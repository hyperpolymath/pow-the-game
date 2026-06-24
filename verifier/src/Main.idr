-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

||| Smoke-test harness for the POW verifier.
|||
||| Exercises `verify` against two concrete cases:
|||   1. Triangle K3 with a valid 3-colouring — must return True.
|||   2. Triangle K3 with an invalid colouring (two adjacent vertices share
|||      colour 0) — must return False.
module Main

import Graph
import Verifier
import System

-- K3: vertices {0, 1, 2} with edges (0,1), (1,2), (0,2)
triangle : Graph
triangle = MkGraph 3
  [ MkEdge 0 1
  , MkEdge 1 2
  , MkEdge 0 2
  ]

-- Valid colouring: vertex 0 → colour 0, vertex 1 → colour 1, vertex 2 → colour 2
validColouring : Colouring
validColouring = [0, 1, 2]

-- Invalid colouring: all vertices assigned colour 0
-- Adjacent vertices 0 and 1 share colour 0 — must be rejected.
invalidColouring : Colouring
invalidColouring = [0, 0, 0]

main : IO ()
main = do
  let t1 = verify triangle validColouring
  let t2 = verify triangle invalidColouring
  if t1
    then putStrLn "PASS: valid K3 colouring accepted"
    else putStrLn "FAIL: valid K3 colouring rejected"
  if not t2
    then putStrLn "PASS: invalid K3 colouring rejected"
    else putStrLn "FAIL: invalid K3 colouring accepted"
  if t1 && not t2
    then do
      putStrLn "All verifier smoke tests PASSED"
      exitSuccess
    else exitWith (ExitFailure 1)
