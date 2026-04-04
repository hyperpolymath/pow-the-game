// SPDX-License-Identifier: AGPL-3.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Monte Carlo pi estimation fragments.
//!
//! Each fragment is an independent batch of random samples. Workers
//! generate `samples` points uniformly in [0,1)^2 and count how many
//! fall inside the unit circle (x^2 + y^2 <= 1). Aggregation sums
//! all (hits, total) pairs; pi ≈ 4 * total_hits / total_samples.
//!
//! ## Reproducibility
//!
//! Each fragment carries a unique `rng_seed`. A worker seeded with the
//! same value must produce the same `hits` count — this allows the
//! coordinator to re-verify any single fragment without re-dispatching.

use rand::{Rng, SeedableRng};
use rand::rngs::StdRng;
use serde::{Deserialize, Serialize};

/// A single Monte Carlo pi estimation work unit.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MonteCarloFragment {
    /// Unique identifier.
    pub id: String,
    /// Number of random samples to generate.
    pub samples: u64,
    /// RNG seed for reproducibility.
    pub rng_seed: u64,
}

/// Produce `count` Monte Carlo fragments, each with `samples_per_fragment`
/// samples and a unique, deterministic RNG seed derived from `base_seed`.
pub fn montecarlo_fragments(count: usize, samples_per_fragment: u64, base_seed: u64) -> Vec<MonteCarloFragment> {
    (0..count)
        .map(|i| MonteCarloFragment {
            id: format!("mc-{base_seed}-{i}"),
            samples: samples_per_fragment,
            rng_seed: base_seed.wrapping_add(i as u64),
        })
        .collect()
}

/// Run one Monte Carlo fragment locally. Returns (hits, total).
///
/// This is the reference implementation that workers are expected to match.
/// It is used in tests to validate convergence and reproducibility.
pub fn run_fragment(frag: &MonteCarloFragment) -> (u64, u64) {
    let mut rng = StdRng::seed_from_u64(frag.rng_seed);
    let hits = (0..frag.samples)
        .filter(|_| {
            let x: f64 = rng.gen();
            let y: f64 = rng.gen();
            x * x + y * y <= 1.0
        })
        .count() as u64;
    (hits, frag.samples)
}

/// Aggregate (hits, total) pairs from multiple fragments into a pi estimate.
pub fn aggregate_pi(results: &[(u64, u64)]) -> f64 {
    let total_hits: u64 = results.iter().map(|(h, _)| h).sum();
    let total_samples: u64 = results.iter().map(|(_, t)| t).sum();
    if total_samples == 0 {
        return 0.0;
    }
    4.0 * total_hits as f64 / total_samples as f64
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::f64::consts::PI;

    #[test]
    fn convergence_within_tolerance() {
        // 20 fragments × 10000 samples = 200K total.
        // At 200K samples, std deviation of estimate ≈ 0.003.
        // A 0.05 tolerance has >10σ margin; failure probability is negligible.
        let frags = montecarlo_fragments(20, 10_000, 42);
        let results: Vec<(u64, u64)> = frags.iter().map(run_fragment).collect();
        let estimate = aggregate_pi(&results);
        let error = (estimate - PI).abs();
        assert!(
            error < 0.05,
            "pi estimate {estimate:.5} is too far from {PI:.5} (error={error:.5})"
        );
    }

    #[test]
    fn reproducibility() {
        // Same seed must produce same result.
        let frag = MonteCarloFragment { id: "test".into(), samples: 1000, rng_seed: 99 };
        let (h1, t1) = run_fragment(&frag);
        let (h2, t2) = run_fragment(&frag);
        assert_eq!((h1, t1), (h2, t2), "same seed must produce same result");
    }

    #[test]
    fn different_seeds_produce_different_results() {
        let a = MonteCarloFragment { id: "a".into(), samples: 1000, rng_seed: 1 };
        let b = MonteCarloFragment { id: "b".into(), samples: 1000, rng_seed: 2 };
        let (ha, _) = run_fragment(&a);
        let (hb, _) = run_fragment(&b);
        // With 1000 samples this is astronomically unlikely to be equal.
        assert_ne!(ha, hb, "different seeds should produce different hit counts");
    }
}
