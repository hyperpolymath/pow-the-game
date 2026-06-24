-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

--[[
  worker_sim_test.lua — GLua worker simulation tests (Target 4 — Grade B)

  Tests the core compute kernel (pow_worker.lua) outside GMod using
  standard Lua 5.1 and the dkjson library.

  Test cases:
    1. Solvable fragment (triangle K3 with valid seed) → "solved" + valid colours
    2. Unsolvable fragment (complete K3 with conflicting seed) → "unsolvable"
    3. Timeout fragment (large search space with near-zero timeout) → "timeout"

  Run: lua5.1 tests/worker/worker_sim_test.lua
       (or: lua tests/worker/worker_sim_test.lua)

  Exit code: 0 = all tests pass, 1 = any test fails.
--]]

-- Locate pow_worker.lua relative to this test file.
local script_dir = debug.getinfo(1, "S").source:match("^@(.*[/\\])") or "./"
local worker_path = script_dir .. "../../worker/glua/pow_worker.lua"

-- Load the worker module.
local ok, worker = pcall(dofile, worker_path)
if not ok then
  io.stderr:write("ERROR: could not load pow_worker.lua: " .. tostring(worker) .. "\n")
  os.exit(1)
end

local PASS = 0
local FAIL = 0

local function pass(msg)
  print("PASS: " .. msg)
  PASS = PASS + 1
end

local function fail(msg)
  print("FAIL: " .. msg)
  FAIL = FAIL + 1
end

local function assert_eq(a, b, msg)
  if a == b then
    pass(msg)
  else
    fail(msg .. string.format(" (expected %s, got %s)", tostring(b), tostring(a)))
  end
end

-- A monotonic clock that returns seconds (os.clock is CPU time, good enough for tests).
local clock = os.clock

-- ── Test 1: Solvable fragment ─────────────────────────────────────────────────
-- Triangle K3 (vertices 0,1,2 with all edges). Seed: vertex 0 = colour 0.
-- A valid colouring exists: 0→0, 1→1, 2→2.

local frag1 = {
  id = "test-solvable",
  kind = "three_colouring",
  payload = {
    n = 3,
    edges = { {0,1}, {1,2}, {0,2} },
    seeds = { { vertex=0, colour=0 } },
  },
  timeout_ms = 5000,
}

local result1 = worker.solve(frag1, clock)
assert_eq(result1.status, "solved", "T4-1: solvable K3 returns solved")
assert_eq(result1.fragment_id, "test-solvable", "T4-1: fragment_id preserved")
if result1.status == "solved" then
  local c = result1.payload.colours
  -- Verify the returned colouring is actually valid.
  local valid = c ~= nil
    and c[1] ~= c[2]  -- edge (0,1): colour 0 ≠ colour 1
    and c[2] ~= c[3]  -- edge (1,2): colour 1 ≠ colour 2
    and c[1] ~= c[3]  -- edge (0,2): colour 0 ≠ colour 2
  if valid then
    pass("T4-1: returned colouring is valid for K3")
  else
    fail("T4-1: returned colouring is INVALID for K3: " .. tostring(c and table.concat(c,",") or "nil"))
  end
end

-- ── Test 2: Unsolvable fragment ───────────────────────────────────────────────
-- K3 with seeds forcing vertex 0 and vertex 1 to both have colour 0.
-- Since (0,1) is an edge, this seed combination is immediately unsolvable.

local frag2 = {
  id = "test-unsolvable",
  kind = "three_colouring",
  payload = {
    n = 3,
    edges = { {0,1}, {1,2}, {0,2} },
    seeds = {
      { vertex=0, colour=0 },
      { vertex=1, colour=0 },
    },
  },
  timeout_ms = 5000,
}

local result2 = worker.solve(frag2, clock)
assert_eq(result2.status, "unsolvable", "T4-2: conflicting seed returns unsolvable")

-- ── Test 3: Timeout fragment ──────────────────────────────────────────────────
-- Uses a mock clock that expires after a small number of calls to guarantee
-- a timeout regardless of actual CPU speed. The graph is solvable (sparse path)
-- so without the timeout it would eventually return "solved".

-- Build a path graph P_20: 0-1-2-...-19 (solvable with 2 colours, but large
-- enough that the backtracker visits many vertices before the mock clock fires).
local path_edges = {}
for i = 0, 18 do path_edges[#path_edges+1] = {i, i+1} end

-- Mock clock: returns 0 for the first 3 calls (start + deadline setup),
-- then returns a time far beyond the deadline to force a timeout.
local mock_calls = 0
local mock_clock = function()
  mock_calls = mock_calls + 1
  if mock_calls <= 3 then
    return 0.0
  end
  return 9999.0  -- well past any deadline
end

local frag3 = {
  id = "test-timeout",
  kind = "three_colouring",
  payload = {
    n = 20,
    edges = path_edges,
    seeds = {},
  },
  timeout_ms = 2000,  -- 2s deadline; mock clock jumps to 9999s after 3 ticks
}

local result3 = worker.solve(frag3, mock_clock)
assert_eq(result3.status, "timeout", "T4-3: mock-clock timeout returns timeout")

-- ── Summary ───────────────────────────────────────────────────────────────────

print("")
print(string.format("Results: %d passed, %d failed", PASS, FAIL))
if FAIL > 0 then os.exit(1) end
