# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# Negative test: callback_url using plain HTTP must be rejected.

let Fragment = {
  id | String | std.contract.from_predicate (fun s => std.string.length s > 0),
  kind | String,
  payload | { .. },
  callback_url
    | String
    | std.contract.from_predicate (fun u => std.string.is_match "^https://" u),
} in

{
  id = "frag-001",
  kind = "three_colouring",
  payload = {},
  callback_url = "http://coordinator.example.com/result",
} | Fragment
