// SPDX-License-Identifier: AGPL-3.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//// Pure state-machine core of the POW coordinator.
////
//// This module contains no BEAM networking or HTTP — just the logic for
//// tracking fragment dispatch and result quorum. A BEAM supervisor tree
//// wraps this in Phase 2.
////
//// ## State machine
////
//// Each fragment moves through: Pending -> Dispatched -> Complete | Failed
////
//// Quorum is achieved when ⌈Q/2⌉+1 workers return the same result.
//// Default Q=3 means 2-of-3 agreement is required.

import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}

/// The problem kind this fragment represents.
pub type FragmentKind {
  ThreeColouring
  MonteCarloPi
}

/// A work unit dispatched to a worker.
pub type Fragment {
  Fragment(
    id: String,
    kind: FragmentKind,
    payload: String,
    timeout_ms: Int,
    quorum: Int,
  )
}

/// The lifecycle state of a fragment.
pub type FragmentStatus {
  /// Waiting to be dispatched.
  Pending
  /// Dispatched to one or more workers; awaiting quorum.
  InProgress(dispatched_to: List(String))
  /// Quorum reached; result accepted.
  Complete(result: String)
  /// Too many dispatch attempts without quorum.
  Failed(reason: String)
}

/// A result submission from a worker.
pub type WorkerResult {
  WorkerResult(
    fragment_id: String,
    worker_id: String,
    status: ResultStatus,
    payload: String,
  )
}

/// The outcome reported by the worker.
pub type ResultStatus {
  Solved
  Unsolvable
  Timeout
  WorkerError
}

/// State of a single fragment tracked by the coordinator.
pub type FragmentState {
  FragmentState(
    fragment: Fragment,
    status: FragmentStatus,
    /// All submitted results, keyed by worker_id.
    submissions: Dict(String, WorkerResult),
  )
}

/// Full coordinator state — all known fragments.
pub type CoordinatorState {
  CoordinatorState(fragments: Dict(String, FragmentState))
}

/// Create a new empty coordinator state.
pub fn new() -> CoordinatorState {
  CoordinatorState(fragments: dict.new())
}

/// Register a new fragment as Pending.
pub fn register(state: CoordinatorState, fragment: Fragment) -> CoordinatorState {
  let fs =
    FragmentState(
      fragment: fragment,
      status: Pending,
      submissions: dict.new(),
    )
  CoordinatorState(fragments: dict.insert(state.fragments, fragment.id, fs))
}

/// Dispatch the next Pending fragment to a worker.
///
/// Returns the fragment and the updated state, or None if no pending
/// fragments are available.
pub fn dispatch(
  state: CoordinatorState,
  worker_id: String,
) -> #(CoordinatorState, Option(Fragment)) {
  let pending =
    dict.to_list(state.fragments)
    |> list.find(fn(kv) {
      let #(_, fs) = kv
      case fs.status {
        Pending -> True
        _ -> False
      }
    })

  case pending {
    Error(Nil) -> #(state, None)
    Ok(#(id, fs)) -> {
      let updated_fs =
        FragmentState(
          ..fs,
          status: InProgress(dispatched_to: [worker_id]),
        )
      let updated_state =
        CoordinatorState(
          fragments: dict.insert(state.fragments, id, updated_fs),
        )
      #(updated_state, Some(fs.fragment))
    }
  }
}

/// Submit a result from a worker.
///
/// Returns the updated state and whether quorum was reached.
pub fn submit_result(
  state: CoordinatorState,
  worker_result: WorkerResult,
) -> #(CoordinatorState, Bool) {
  case dict.get(state.fragments, worker_result.fragment_id) {
    Error(Nil) ->
      // Unknown fragment — ignore.
      #(state, False)
    Ok(fs) -> {
      let updated_submissions =
        dict.insert(fs.submissions, worker_result.worker_id, worker_result)
      let quorum_threshold = { fs.fragment.quorum / 2 } + 1
      let quorum_reached =
        check_quorum(dict.values(updated_submissions), quorum_threshold)
      let new_status = case quorum_reached {
        True -> Complete(result: worker_result.payload)
        False ->
          case fs.status {
            InProgress(workers) ->
              InProgress(dispatched_to: [worker_result.worker_id, ..workers])
            other -> other
          }
      }
      let updated_fs =
        FragmentState(
          ..fs,
          status: new_status,
          submissions: updated_submissions,
        )
      let updated_state =
        CoordinatorState(
          fragments: dict.insert(
            state.fragments,
            worker_result.fragment_id,
            updated_fs,
          ),
        )
      #(updated_state, quorum_reached)
    }
  }
}

/// Get the current status of a fragment.
pub fn fragment_status(
  state: CoordinatorState,
  fragment_id: String,
) -> Option(FragmentStatus) {
  case dict.get(state.fragments, fragment_id) {
    Ok(fs) -> Some(fs.status)
    Error(Nil) -> None
  }
}

// ── Internal helpers ──────────────────────────────────────────────────────────

/// Check if any result payload appears at least `threshold` times.
fn check_quorum(results: List(WorkerResult), threshold: Int) -> Bool {
  let solved =
    list.filter(results, fn(r) {
      case r.status {
        Solved -> True
        _ -> False
      }
    })
  // Group by payload and check if any group meets threshold.
  list.any(solved, fn(r) {
    let matching =
      list.count(solved, fn(other) { other.payload == r.payload })
    matching >= threshold
  })
}
