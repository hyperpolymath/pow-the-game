# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# Fragment schema contracts for POW work units.
#
# This file defines the authoritative Nickel contracts for Fragment and Result
# types. It is evaluated by run_schema_tests.sh to validate both positive
# (well-formed) and negative (malformed) test cases.
#
# A contract here is the single source of truth for the wire format shared
# between the Rust fragmenter, Gleam coordinator, and Lua workers.

let Schema = {

  FragmentKind
    | doc "The problem class for a work unit."
    = std.contract.from_predicate (fun v =>
        v == "three_colouring" || v == "monte_carlo_pi"
      ),

  Fragment = {
    id
      | doc "Unique fragment identifier (UUIDv7 or similar unique string)."
      | String
      | std.contract.from_predicate (fun s => std.string.length s > 0),

    kind | FragmentKind,

    schema_version
      | doc "Schema version number as a string digit."
      | String
      | std.contract.from_predicate (fun v => std.string.is_match "^[0-9]+$" v)
      | default = "1",

    payload
      | doc "Problem-specific payload object."
      | { .. },

    timeout_ms
      | doc "Maximum compute time in milliseconds (1..30000)."
      | Number
      | std.contract.from_predicate (fun t => t > 0 && t <= 30000)
      | default = 2000,

    quorum
      | doc "Number of independent verifications required (1..10)."
      | Number
      | std.contract.from_predicate (fun q => q >= 1 && q <= 10)
      | default = 3,

    callback_url
      | doc "Coordinator callback URL (must use HTTPS)."
      | String
      | std.contract.from_predicate (fun u =>
          std.string.is_match "^https://" u
        ),
  },

  ThreeColouringPayload = {
    n
      | doc "Number of vertices."
      | Number
      | std.contract.from_predicate (fun x => x > 0),

    edges
      | doc "Adjacency list as array of [u, v] pairs."
      | Array (Array Number),

    seeds
      | doc "Fixed vertex-colour assignments defining the search subspace."
      | Array { vertex | Number, colour | Number },
  },

  MonteCarloPiPayload = {
    samples
      | doc "Number of random samples to generate."
      | Number
      | std.contract.from_predicate (fun x => x > 0),

    rng_seed
      | doc "RNG seed for reproducibility."
      | Number,
  },

} in

# ── Positive test cases (must evaluate without error) ──────────────────────────

let valid_three_colouring_fragment =
  {
    id = "frag-abc-123",
    kind = "three_colouring",
    schema_version = "1",
    payload = {
      n = 3,
      edges = [[0, 1], [1, 2], [0, 2]],
      seeds = [{ vertex = 0, colour = 0 }],
    },
    timeout_ms = 2000,
    quorum = 3,
    callback_url = "https://coordinator.example.com/result",
  } | Schema.Fragment
in

let valid_monte_carlo_fragment =
  {
    id = "mc-001",
    kind = "monte_carlo_pi",
    payload = { samples = 10000, rng_seed = 42 },
    callback_url = "https://coordinator.example.com/result",
  } | Schema.Fragment
in

# Return both valid cases — if the file evaluates, both contracts passed.
{
  valid_three_colouring = valid_three_colouring_fragment.id,
  valid_monte_carlo = valid_monte_carlo_fragment.id,
}
