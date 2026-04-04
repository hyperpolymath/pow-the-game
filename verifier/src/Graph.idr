-- SPDX-License-Identifier: AGPL-3.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

||| Graph and colouring data types for the POW verifier.
|||
||| Phase 0 uses Nat for vertex indices and colours to keep the type-checker
||| straightforward. Phase 1 will migrate to Fin-indexed types for full
||| dependent-type safety at the cost of more complex proofs.
|||
||| A valid 3-colouring assigns each vertex a colour in {0, 1, 2} such that
||| no two adjacent vertices share the same colour.
module Graph

%default total

||| A vertex index (0-based natural number).
public export
Vertex : Type
Vertex = Nat

||| A colour in {0, 1, 2}. Values >= 3 are treated as invalid.
public export
Colour : Type
Colour = Nat

||| An undirected edge between two vertices.
public export
record Edge where
  constructor MkEdge
  ||| First endpoint (vertex index).
  src : Vertex
  ||| Second endpoint (vertex index).
  dst : Vertex

||| An undirected graph as an edge list.
public export
record Graph where
  constructor MkGraph
  ||| Number of vertices.
  n : Nat
  ||| Edge list (unordered pairs).
  edges : List Edge

||| A colouring maps vertex indices to colours.
||| Represented as a list: index i gives the colour of vertex i.
public export
Colouring : Type
Colouring = List Colour
