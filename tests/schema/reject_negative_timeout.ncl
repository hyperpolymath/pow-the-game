# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# Negative test: timeout_ms <= 0 must be rejected.

let Fragment = {
  id | String | std.contract.from_predicate (fun s => std.string.length s > 0),
  kind | String,
  payload | { .. },
  timeout_ms
    | Number
    | std.contract.from_predicate (fun t => t > 0 && t <= 30000),
  callback_url
    | String
    | std.contract.from_predicate (fun u => std.string.is_match "^https://" u),
} in

{
  id = "frag-001",
  kind = "three_colouring",
  payload = {},
  timeout_ms = -1,
  callback_url = "https://coordinator.example.com/result",
} | Fragment
