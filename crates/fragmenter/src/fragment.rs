// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Fragment types and the graph fragmenter.
//!
//! A [`Fragment`] is a single work unit dispatched to a game-mod worker.
//! For 3-colouring, each fragment fixes the colours of `seed_depth` vertices
//! and asks the worker to search the remaining assignment space.
//!
//! ## Partition guarantee
//!
//! [`fragment_graph`] produces exactly 3^k fragments (k = seed_depth).
//! Each fragment corresponds to a unique prefix assignment of the first k
//! vertex indices. The union of their search spaces covers all possible
//! colourings, and no two fragments share a valid colouring (they are
//! disjoint by construction — any colouring either agrees with the seed
//! or it doesn't).

use serde::{Deserialize, Serialize};
use crate::Graph;

/// The kind of computational problem a fragment represents.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FragmentKind {
    /// Search for a valid 3-colouring consistent with seed assignments.
    ThreeColouring,
    /// Monte Carlo pi estimation with a given RNG seed.
    MonteCarloPi,
}

/// A single seed assignment: vertex index and its fixed colour (0, 1, or 2).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SeedAssignment {
    /// Vertex index in [0, graph.n).
    pub vertex: usize,
    /// Fixed colour in {0, 1, 2}.
    pub colour: u8,
}

/// A work unit dispatched to a game-mod worker.
///
/// The `seeds` field constrains the search space: the worker must find a valid
/// 3-colouring that agrees with every seed assignment, or report `Unsolvable`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Fragment {
    /// Unique fragment identifier (UUID string).
    pub id: String,
    /// Problem kind.
    pub kind: FragmentKind,
    /// The graph to colour.
    pub graph: Graph,
    /// Fixed vertex-colour assignments that define this fragment's subspace.
    pub seeds: Vec<SeedAssignment>,
    /// Maximum compute time in milliseconds before the worker should give up.
    pub timeout_ms: u32,
    /// Number of independent workers that must agree before the result is accepted.
    pub quorum: u8,
}

/// Decompose a 3-colouring problem into 3^seed_depth independent fragments.
///
/// Each fragment fixes the colours of the first `seed_depth` vertices of
/// `graph` to a unique combination, then asks a worker to search the rest.
///
/// # Panics
///
/// Panics if `seed_depth >= graph.n` (no unseed vertices to search).
pub fn fragment_graph(graph: &Graph, seed_depth: usize, timeout_ms: u32, quorum: u8) -> Vec<Fragment> {
    assert!(seed_depth < graph.n, "seed_depth must be < graph.n");

    let count = 3usize.pow(seed_depth as u32);
    let mut fragments = Vec::with_capacity(count);

    for i in 0..count {
        // Decode i as a base-3 number to get the colour for each seed vertex.
        let seeds: Vec<SeedAssignment> = (0..seed_depth)
            .map(|pos| {
                let colour = ((i / 3usize.pow(pos as u32)) % 3) as u8;
                SeedAssignment { vertex: pos, colour }
            })
            .collect();

        fragments.push(Fragment {
            id: uuid::Uuid::new_v4().to_string(),
            kind: FragmentKind::ThreeColouring,
            graph: graph.clone(),
            seeds,
            timeout_ms,
            quorum,
        });
    }

    fragments
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::Graph;

    fn triangle() -> Graph {
        Graph::new(3, vec![(0, 1), (1, 2), (0, 2)])
    }

    #[test]
    fn fragment_count_is_three_to_the_k() {
        let g = triangle();
        let frags = fragment_graph(&g, 1, 2000, 3);
        assert_eq!(frags.len(), 3);

        let frags2 = fragment_graph(&g, 2, 2000, 3);
        assert_eq!(frags2.len(), 9);
    }

    #[test]
    fn seeds_cover_all_colour_combinations() {
        let g = Graph::new(5, vec![]);
        let frags = fragment_graph(&g, 2, 2000, 3);
        // Collect all (seed[0].colour, seed[1].colour) pairs
        let mut combos: Vec<(u8, u8)> = frags.iter()
            .map(|f| (f.seeds[0].colour, f.seeds[1].colour))
            .collect();
        combos.sort();
        combos.dedup();
        assert_eq!(combos.len(), 9, "expected 9 unique seed combos for depth=2");
    }

    #[test]
    fn all_seeds_have_valid_colours() {
        let g = Graph::new(10, vec![]);
        let frags = fragment_graph(&g, 3, 2000, 3);
        for f in &frags {
            for s in &f.seeds {
                assert!(s.colour < 3, "colour {} out of range", s.colour);
            }
        }
    }

    #[test]
    fn fragment_graph_matches_original_graph() {
        let g = triangle();
        let frags = fragment_graph(&g, 1, 2000, 3);
        for f in &frags {
            assert_eq!(f.graph, g, "graph in fragment must match original");
        }
    }
}
