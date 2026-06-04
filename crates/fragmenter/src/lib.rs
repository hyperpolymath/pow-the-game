// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! # fragmenter
//!
//! Decomposes combinatorial problems into independently solvable work units
//! (fragments) for the POW distributed compute system.
//!
//! ## Responsibilities
//!
//! - [`Graph`]: adjacency-list representation of an undirected graph
//! - [`fragment_graph`]: partition the 3-colouring search space by fixing k
//!   seed vertices to all possible colour combinations (produces 3^k fragments)
//! - [`montecarlo_fragments`]: split a Monte Carlo estimation into N independent
//!   sample batches with distinct RNG seeds
//!
//! ## Invariants
//!
//! - Every fragment produced by [`fragment_graph`] covers a disjoint subspace
//! - The union of all fragment subspaces equals the full assignment space
//! - No fragment modifies the graph; the adjacency list is shared read-only
//!
//! ## Non-responsibilities
//!
//! This crate does not perform search — it only produces the fragment
//! descriptors that workers consume. Workers are Lua scripts running inside
//! game mods.

pub mod graph;
pub mod fragment;
pub mod montecarlo;

pub use graph::Graph;
pub use fragment::{Fragment, FragmentKind, SeedAssignment, fragment_graph};
pub use montecarlo::{MonteCarloFragment, montecarlo_fragments, aggregate_pi};
