// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Property-based tests for the graph fragmenter.
//!
//! These tests validate the partition guarantee: for any graph G and seed
//! depth k, the fragments produced by [`fragment_graph`] form a complete,
//! disjoint partition of the 3-colouring search space.

use fragmenter::{Graph, fragment_graph};
use proptest::prelude::*;

/// Generate a random graph with n in [3, 15] vertices and edges chosen
/// uniformly from all possible pairs.
fn arb_graph() -> impl Strategy<Value = Graph> {
    (3usize..=15, prop::collection::vec(prop::bool::ANY, 0..=105)).prop_map(|(n, coin_flips)| {
        let mut edges = Vec::new();
        let mut flip_idx = 0;
        for u in 0..n {
            for v in (u + 1)..n {
                if flip_idx < coin_flips.len() && coin_flips[flip_idx] {
                    edges.push((u, v));
                }
                flip_idx += 1;
            }
        }
        Graph::new(n, edges)
    })
}

proptest! {
    /// Fragment count is exactly 3^k.
    #[test]
    fn fragment_count(n in 3usize..=10, k in 1usize..=3) {
        prop_assume!(k < n);
        let g = Graph::new(n, vec![]);
        let frags = fragment_graph(&g, k, 2000, 3);
        prop_assert_eq!(frags.len(), 3usize.pow(k as u32));
    }

    /// Every fragment carries the complete original graph.
    #[test]
    fn fragments_carry_full_graph(graph in arb_graph(), k in 1usize..=2) {
        prop_assume!(k < graph.n);
        let frags = fragment_graph(&graph, k, 2000, 3);
        for f in &frags {
            prop_assert_eq!(&f.graph, &graph);
        }
    }

    /// All seed colour combinations are distinct across fragments.
    #[test]
    fn seed_combinations_are_unique(n in 3usize..=10, k in 1usize..=3) {
        prop_assume!(k < n);
        let g = Graph::new(n, vec![]);
        let frags = fragment_graph(&g, k, 2000, 3);
        let mut combos: Vec<Vec<u8>> = frags.iter()
            .map(|f| f.seeds.iter().map(|s| s.colour).collect())
            .collect();
        combos.sort();
        combos.dedup();
        prop_assert_eq!(combos.len(), frags.len());
    }

    /// All seed colours are in {0, 1, 2}.
    #[test]
    fn seed_colours_are_valid(graph in arb_graph(), k in 1usize..=2) {
        prop_assume!(k < graph.n);
        let frags = fragment_graph(&graph, k, 2000, 3);
        for f in &frags {
            for s in &f.seeds {
                prop_assert!(s.colour < 3, "colour {} is out of range", s.colour);
                prop_assert!(s.vertex < graph.n, "vertex {} is out of range", s.vertex);
            }
        }
    }
}
