-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

||| Formally verified result checker for 3-colouring.
|||
||| ## What this module proves
|||
||| `verifyCorrect` is the core soundness theorem: if `verify g c = True`,
||| then `c` is a valid 3-colouring of `g` (i.e., `ValidColouring g c` holds).
|||
||| `ValidColouring g c` is defined as `verify g c = True` — this makes
||| `verifyCorrect` a trivial proof by identity. The non-trivial work in
||| Phase 1 is proving a richer `ValidColouring` that speaks about edges
||| directly, and then showing `verify` computes that property correctly.
|||
||| ## Phase 0 status
|||
||| The current `ValidColouring` is defined as `verify g c = True`, so
||| `verifyCorrect` is proven by `prf` (identity). This is legitimate:
||| it establishes the interface that Phase 1 will strengthen.
|||
||| TODO(Phase 1): Redefine `ValidColouring g c` as
|||   `All (\e => lookupColour e.src c /= lookupColour e.dst c) g.edges`
||| and prove that `verify g c = True` implies this richer property.
module Verifier

import Graph

%default total

||| Look up a vertex colour in the colouring list.
||| Returns 3 (an out-of-range sentinel) if the vertex index is out of bounds —
||| this ensures any out-of-range access fails the colour validity check.
export
lookupColour : Vertex -> Colouring -> Colour
lookupColour Z     (c :: _)  = c
lookupColour (S k) (_ :: cs) = lookupColour k cs
lookupColour _     []        = 3  -- sentinel: invalid colour

||| Check one edge: the two endpoints must have different, valid colours.
|||
||| Returns True iff src and dst have different colours and both are in {0,1,2}.
export
checkEdge : Edge -> Colouring -> Bool
checkEdge e c =
  let sc = lookupColour e.src c
      dc = lookupColour e.dst c
  in sc /= dc && sc < 3 && dc < 3

||| Verify a complete 3-colouring by checking every edge.
|||
||| Returns True iff every edge in `g` is properly 3-coloured by `c`.
||| Total: `all` on a finite list terminates.
export
verify : Graph -> Colouring -> Bool
verify g c = all (\e => checkEdge e c) g.edges

||| A colouring is valid for a graph iff `verify g c` returns True.
|||
||| Phase 0 definition: makes `verifyCorrect` provable by identity.
||| Phase 1 will strengthen this to speak about edges directly.
public export
ValidColouring : Graph -> Colouring -> Type
ValidColouring g c = verify g c = True

||| Soundness theorem: `verify g c = True` implies `ValidColouring g c`.
|||
||| With the current Phase 0 definition of `ValidColouring`, this is
||| trivially true (both sides are `verify g c = True`).
|||
||| This function exists to establish the interface: any code that calls
||| `verifyCorrect` is guaranteed a `ValidColouring`, and when Phase 1
||| strengthens `ValidColouring`, only this function's proof needs updating.
export
verifyCorrect : (g : Graph) -> (c : Colouring) ->
                verify g c = True ->
                ValidColouring g c
verifyCorrect g c prf = prf
