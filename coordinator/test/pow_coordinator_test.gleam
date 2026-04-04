// SPDX-License-Identifier: AGPL-3.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//// Coordinator protocol round-trip tests (Target 6 — Grade B).
////
//// Tests cover the full state-machine lifecycle:
////   1. Register a fragment
////   2. Dispatch to a worker
////   3. Submit results and track quorum
////   4. Confirm complete status on quorum
////   5. Reject results for unknown fragment IDs

import gleeunit
import gleeunit/should
import gleam/option.{None, Some}
import pow_coordinator.{
  type Fragment, type WorkerResult, Complete, Fragment, Pending, Solved,
  ThreeColouring, WorkerResult, dispatch, fragment_status, new, register,
  submit_result,
}

pub fn main() {
  gleeunit.main()
}

fn test_fragment() -> Fragment {
  Fragment(
    id: "frag-001",
    kind: ThreeColouring,
    payload: "{\"n\":3,\"edges\":[[0,1],[1,2]]}",
    timeout_ms: 2000,
    quorum: 3,
  )
}

fn make_result(frag_id: String, worker_id: String, payload: String) -> WorkerResult {
  WorkerResult(
    fragment_id: frag_id,
    worker_id: worker_id,
    status: Solved,
    payload: payload,
  )
}

/// T6-1: A registered fragment is initially Pending.
pub fn register_sets_pending_test() {
  let state = new() |> register(test_fragment())
  fragment_status(state, "frag-001")
  |> should.equal(Some(Pending))
}

/// T6-2: Dispatch returns the fragment and transitions it to InProgress.
pub fn dispatch_returns_fragment_test() {
  let state = new() |> register(test_fragment())
  let #(updated, result) = dispatch(state, "worker-1")
  result |> should.equal(Some(test_fragment()))
  fragment_status(updated, "frag-001")
  |> should.not_equal(Some(Pending))
}

/// T6-3: Submitting 2-of-3 matching results reaches quorum.
pub fn quorum_reached_on_two_of_three_test() {
  let state = new() |> register(test_fragment())
  let result_a = make_result("frag-001", "worker-1", "[0,1,2]")
  let result_b = make_result("frag-001", "worker-2", "[0,1,2]")

  let #(s1, q1) = submit_result(state, result_a)
  q1 |> should.equal(False)

  let #(s2, q2) = submit_result(s1, result_b)
  q2 |> should.equal(True)

  case fragment_status(s2, "frag-001") {
    Some(Complete(_)) -> Nil
    _other -> should.fail()
  }
}

/// T6-4: A result for an unknown fragment ID is silently ignored.
pub fn unknown_fragment_ignored_test() {
  let state = new()
  let ghost = make_result("no-such-fragment", "worker-1", "[0,1,2]")
  let #(updated, quorum) = submit_result(state, ghost)
  quorum |> should.equal(False)
  fragment_status(updated, "no-such-fragment") |> should.equal(None)
}

/// T6-5: Mismatched payloads from two workers do not reach quorum (Q=3).
pub fn mismatched_payloads_do_not_reach_quorum_test() {
  let state = new() |> register(test_fragment())
  let result_a = make_result("frag-001", "worker-1", "[0,1,2]")
  let result_b = make_result("frag-001", "worker-2", "[1,0,2]")

  let #(s1, _) = submit_result(state, result_a)
  let #(s2, q) = submit_result(s1, result_b)
  q |> should.equal(False)

  case fragment_status(s2, "frag-001") {
    Some(Complete(_)) -> should.fail()
    _ -> Nil
  }
}

/// T6-6: No work available returns None from dispatch.
pub fn dispatch_with_no_pending_returns_none_test() {
  let state = new()
  let #(_, result) = dispatch(state, "worker-1")
  result |> should.equal(None)
}
