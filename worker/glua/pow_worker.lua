-- SPDX-License-Identifier: AGPL-3.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

--[[
  pow_worker.lua — Core compute kernel for the POW Garry's Mod worker.

  This file contains the pure computation logic, isolated from all GMod-specific
  APIs (http.Fetch, game.GetWorld, etc.) so it can be tested outside GMod with
  standard Lua 5.1.

  ## Responsibilities

    - Deserialise a JSON work unit into a Lua table
    - Execute a bounded 3-colouring backtracking search given seed constraints
    - Serialise the result back to JSON
    - Respect the timeout_ms field by checking elapsed time during search

  ## Non-responsibilities

    - HTTP polling (handled by the GMod addon wrapper)
    - Player UI (handled by the GMod addon wrapper)
    - Persistent storage

  ## Usage (outside GMod)

    local worker = require("pow_worker")
    local result = worker.solve(fragment_table, os.clock)

  ## Usage (inside GMod addon)

    include("pow_worker.lua")   -- standard GMod file inclusion
    local result = PowWorker.solve(fragment, SysTime)
--]]

-- JSON library (dkjson — pure Lua, single file).
-- In GMod this is replaced by util.TableToJSON / util.JSONToTable.
local json
if pcall(function() json = require("dkjson") end) then
  -- dkjson available (test environment)
else
  -- Fallback: minimal JSON encode/decode for test harness
  json = {
    encode = function(t) return tostring(t) end,
    decode = function(s) return nil, "no JSON library" end,
  }
end

local M = {}

-- ── Colour constants ──────────────────────────────────────────────────────────

local NUM_COLOURS = 3

-- ── 3-Colouring backtracking search ──────────────────────────────────────────

--[[
  Build an adjacency set for fast conflict checking.
  Returns a table: adj[u][v] = true if (u,v) is an edge.
--]]
local function build_adj(n, edges)
  local adj = {}
  for i = 0, n - 1 do adj[i] = {} end
  for _, edge in ipairs(edges) do
    local u, v = edge[1], edge[2]
    adj[u][v] = true
    adj[v][u] = true
  end
  return adj
end

--[[
  Check if assigning `colour` to vertex `v` is consistent with current
  partial assignment `colours` given adjacency `adj`.
--]]
local function is_consistent(v, colour, colours, adj)
  for neighbour, _ in pairs(adj[v]) do
    if colours[neighbour] == colour then
      return false
    end
  end
  return true
end

--[[
  Backtracking search for a valid 3-colouring.

  Params:
    v       (number)  current vertex index (0-based)
    n       (number)  total vertex count
    colours (table)   partial assignment: colours[i] = colour or nil
    adj     (table)   adjacency set from build_adj
    deadline (number) os.clock() or SysTime() value after which we abort
    clock   (function) clock function returning current time

  Returns: "solved", "unsolvable", or "timeout"
--]]
local function backtrack(v, n, colours, adj, deadline, clock)
  -- All vertices assigned — valid colouring found.
  if v >= n then return "solved" end

  -- Check timeout before processing each vertex.
  if clock() > deadline then return "timeout" end

  -- Skip vertices with a seed assignment already set.
  if colours[v] ~= nil then
    return backtrack(v + 1, n, colours, adj, deadline, clock)
  end

  for c = 0, NUM_COLOURS - 1 do
    if is_consistent(v, c, colours, adj) then
      colours[v] = c
      local result = backtrack(v + 1, n, colours, adj, deadline, clock)
      if result ~= "unsolvable" then return result end
      colours[v] = nil
    end
  end

  return "unsolvable"
end

-- ── Public API ────────────────────────────────────────────────────────────────

--[[
  Solve a 3-colouring fragment.

  Params:
    fragment (table)    deserialized work unit with fields:
                          .payload.n      (number)  vertex count
                          .payload.edges  (table)   edge list [[u,v], ...]
                          .payload.seeds  (table)   [{vertex,colour}, ...]
                          .timeout_ms     (number)  timeout in milliseconds
    clock    (function) returns current time in seconds (os.clock or SysTime)

  Returns a table:
    {
      fragment_id = "...",
      worker_id   = "pow-lua-worker",
      status      = "solved" | "unsolvable" | "timeout" | "error",
      payload     = { colours = [...] } | {},
      compute_ms  = <elapsed milliseconds>,
    }
--]]
function M.solve(fragment, clock)
  local start = clock()
  local payload = fragment.payload
  local n = payload.n
  local edges = payload.edges or {}
  local seeds = payload.seeds or {}
  local timeout_ms = fragment.timeout_ms or 2000
  local deadline = start + timeout_ms / 1000.0

  local adj = build_adj(n, edges)

  -- Initialise colour array with seed assignments.
  local colours = {}
  for i = 0, n - 1 do colours[i] = nil end
  for _, seed in ipairs(seeds) do
    colours[seed.vertex] = seed.colour
  end

  -- Validate seeds: if two seeded adjacent vertices share a colour, immediately unsolvable.
  for _, seed in ipairs(seeds) do
    if not is_consistent(seed.vertex, seed.colour, colours, adj) then
      -- Temporarily clear this vertex to check its neighbours.
      colours[seed.vertex] = nil
      if not is_consistent(seed.vertex, seed.colour, colours, adj) then
        local elapsed = (clock() - start) * 1000
        return {
          fragment_id = fragment.id,
          worker_id = "pow-lua-worker",
          status = "unsolvable",
          payload = {},
          compute_ms = elapsed,
        }
      end
      colours[seed.vertex] = seed.colour
    end
  end

  local outcome = backtrack(0, n, colours, adj, deadline, clock)
  local elapsed = (clock() - start) * 1000

  local result_payload = {}
  if outcome == "solved" then
    local colour_list = {}
    for i = 0, n - 1 do
      colour_list[i + 1] = colours[i]
    end
    result_payload = { colours = colour_list }
  end

  return {
    fragment_id = fragment.id,
    worker_id = "pow-lua-worker",
    status = outcome,
    payload = result_payload,
    compute_ms = elapsed,
  }
end

--[[
  Deserialise a JSON string into a fragment table.
  In GMod, replace json.decode with util.JSONToTable.
--]]
function M.decode_fragment(json_str)
  local t, pos, err = json.decode(json_str)
  if err then return nil, err end
  return t, nil
end

--[[
  Serialise a result table to a JSON string.
  In GMod, replace json.encode with util.TableToJSON.
--]]
function M.encode_result(result)
  return json.encode(result)
end

return M
