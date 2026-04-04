;; SPDX-License-Identifier: AGPL-3.0
(bot-directive
  (bot "echidnabot")
  (scope "formal verification and fuzzing")
  (allow ("analysis" "fuzzing" "proof checks"))
  (deny ("write to core modules" "write to bindings"))
  (notes "May open findings; code changes require explicit approval"))
