// SPDX-License-Identifier: AGPL-3.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Undirected graph representation for the fragmenter.
//!
//! Edges are stored as an adjacency list. Vertex indices are 0-based.
//! Self-loops are not supported (and are ignored if present in input).

use serde::{Deserialize, Serialize};

/// An undirected graph stored as a list of edges.
///
/// Vertices are identified by index in [0, n). Edges are unordered pairs
/// of vertex indices; each edge (u, v) is stored once (not duplicated as
/// both (u,v) and (v,u)).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Graph {
    /// Number of vertices.
    pub n: usize,
    /// Edges as (u, v) pairs, where u < v and both are in [0, n).
    pub edges: Vec<(usize, usize)>,
}

impl Graph {
    /// Construct a graph from a vertex count and edge list.
    ///
    /// Edges with equal endpoints (self-loops) are silently dropped.
    /// Edges with out-of-range endpoints panic in debug mode.
    pub fn new(n: usize, edges: Vec<(usize, usize)>) -> Self {
        let edges = edges
            .into_iter()
            .filter(|&(u, v)| {
                debug_assert!(u < n && v < n, "edge ({u},{v}) out of range for n={n}");
                u != v
            })
            .map(|(u, v)| if u < v { (u, v) } else { (v, u) })
            .collect();
        Graph { n, edges }
    }

    /// Generate a random Erdős–Rényi G(n, p) graph.
    ///
    /// Each possible edge is included independently with probability `p`.
    /// Uses `rng` for reproducibility.
    pub fn random_gnp(n: usize, p: f64, rng: &mut impl rand::Rng) -> Self {
        use rand::Rng;
        let mut edges = Vec::new();
        for u in 0..n {
            for v in (u + 1)..n {
                if rng.gen::<f64>() < p {
                    edges.push((u, v));
                }
            }
        }
        Graph { n, edges }
    }

    /// Returns the number of edges.
    pub fn edge_count(&self) -> usize {
        self.edges.len()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn self_loops_are_dropped() {
        let g = Graph::new(3, vec![(0, 0), (1, 2)]);
        assert_eq!(g.edges, vec![(1, 2)]);
    }

    #[test]
    fn edges_are_normalised() {
        let g = Graph::new(3, vec![(2, 0)]);
        assert_eq!(g.edges, vec![(0, 2)]);
    }
}
