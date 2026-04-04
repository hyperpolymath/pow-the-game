# SPDX-License-Identifier: AGPL-3.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# Negative test: fragment missing `id` field must be rejected.

let Fragment = {
  id
    | String
    | std.contract.from_predicate (fun s => std.string.length s > 0),
  kind | String,
  payload | { .. },
  callback_url
    | String
    | std.contract.from_predicate (fun u => std.string.is_match "^https://" u),
} in

# Missing `id` — this MUST fail contract evaluation.
{
  kind = "three_colouring",
  payload = {},
  callback_url = "https://example.com/result",
} | Fragment
