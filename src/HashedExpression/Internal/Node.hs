-- |
-- Module      :  HashedExpression.Internal.Node
-- Copyright   :  (c) OCA 2020
-- License     :  MIT (see the LICENSE file)
-- Maintainer  :  anandc@mcmaster.ca
-- Stability   :  provisional
-- Portability :  unportable
--
-- This module contains a variety of helper functions for working with the 'Node' type, including stuff like finding the ElementType of a
-- Node, returning a Node's arguments, returning a Node's shape, etc
module HashedExpression.Internal.Node
  ( nodeTypeWeight,
    sameOp,
    opArgs,
    retrieveElementType,
    retrieveNode,
    retrieveOp,
    retrieveShape,
    expressionElementType,
    expressionNode,
    expressionOp,
    expressionShape,
  )
where

import qualified Data.IntMap.Strict as IM
import Data.List (sort)
import GHC.Stack (HasCallStack)
import HashedExpression.Internal.Expression

-- | Compute the ElementType (i.e 'R','C','Covector') of an 'Op' (requires the base 'ExpressionMap' as context)
-- opElementType ::
--  HasCallStack =>
--  -- | Node to find the ElementType of
--  Op ->
--  -- | base Expression containing the Node
--  ExpressionMap ->
--  -- | resulting ElementType
--  ET
-- opElementType op mp =
--  case op of
--    Var _ -> R
--    DVar _ -> Covector
--    Const _ -> R
--    Sum et _ -> et
--    Mul et _ -> et
--    Power _ arg -> retrieveElementType arg mp
--    Neg et _ -> et
--    Scale et _ _ -> et
--    Div _ _ -> R
--    Sqrt _ -> R
--    Sin _ -> R
--    Cos _ -> R
--    Tan _ -> R
--    Exp _ -> R
--    Log _ -> R
--    Sinh _ -> R
--    Cosh _ -> R
--    Tanh _ -> R
--    Asin _ -> R
--    Acos _ -> R
--    Atan _ -> R
--    Asinh _ -> R
--    Acosh _ -> R
--    Atanh _ -> R
--    RealImag _ _ -> C -- from real and imagine
--    RealPart _ -> R -- extract real part
--    ImagPart _ -> R -- extract imaginary part
--    InnerProd et _ _ -> et
--    Piecewise _ _ branches ->
--      maximum . map (`retrieveElementType` mp) $ branches
--    Rotate _ arg -> retrieveElementType arg mp
--    ReFT arg
--      | retrieveElementType arg mp == Covector -> Covector
--      | otherwise -> R
--    ImFT arg
--      | retrieveElementType arg mp == Covector -> Covector
--      | otherwise -> R
--    TwiceImFT arg
--      | retrieveElementType arg mp == Covector -> Covector
--      | otherwise -> R
--    TwiceReFT arg
--      | retrieveElementType arg mp == Covector -> Covector
--      | otherwise -> R

-- | For ordering things inside 'Sum' or 'Product' so we can write rules like
--
-- @
--   restOfProduct ~* (x +: y) ~* (z +: w) |.~~~~~~> restOfProduct ~*
--   restOfSum ~+ (x +: y) ~+ (u +: v) |.~~~~~~> restOfSum ~+ ((x + u) +: (y + v))
--   ...
-- @
nodeTypeWeight :: HasCallStack => Op -> Int
nodeTypeWeight node =
  case node of
    Var {} -> 1
    DVar {} -> 6666 -- After Scale
    Const {} -> 0
    Sum {} -> 9999 -- Sum at the end
    Mul {} -> 3
    Power {} -> 28
    Neg {} -> 4
    Scale {} -> 7777 -- Right after RealImag
    Div {} -> 6
    Sqrt {} -> 7
    Sin {} -> 8
    Cos {} -> 9
    Tan {} -> 10
    Exp {} -> 11
    Log {} -> 12
    Sinh {} -> 13
    Cosh {} -> 14
    Tanh {} -> 15
    Asin {} -> 16
    Acos {} -> 17
    Atan {} -> 18
    Asinh {} -> 19
    Acosh {} -> 20
    Atanh {} -> 21
    RealImag {} -> 8888 -- At the end right after sum
    RealPart {} -> 23
    ImagPart {} -> 24
    InnerProd {} -> 25
    Piecewise {} -> 26
    Rotate {} -> 27
    ReFT {} -> 28
    ImFT {} -> 29
    TwiceReFT {} -> 30
    TwiceImFT {} -> 31

-- | Equality for 'Node' types (i.e same constructor), not equality of hash
sameOp :: HasCallStack => Op -> Op -> Bool
sameOp node1 node2 = nodeTypeWeight node1 == nodeTypeWeight node2

-- | Retrieve the parameters (i.e 'Args') attached to a given 'Node'
opArgs :: Op -> Args
opArgs node =
  case node of
    Var _ -> []
    DVar _ -> []
    Const _ -> []
    Sum args -> args
    Mul args -> args
    Power _ arg -> [arg]
    Neg arg -> [arg]
    Scale arg1 arg2 -> [arg1, arg2]
    Div arg1 arg2 -> [arg1, arg2]
    Sqrt arg -> [arg]
    Sin arg -> [arg]
    Cos arg -> [arg]
    Tan arg -> [arg]
    Exp arg -> [arg]
    Log arg -> [arg]
    Sinh arg -> [arg]
    Cosh arg -> [arg]
    Tanh arg -> [arg]
    Asin arg -> [arg]
    Acos arg -> [arg]
    Atan arg -> [arg]
    Asinh arg -> [arg]
    Acosh arg -> [arg]
    Atanh arg -> [arg]
    RealImag arg1 arg2 -> [arg1, arg2]
    RealPart arg -> [arg]
    ImagPart arg -> [arg]
    InnerProd arg1 arg2 -> [arg1, arg2]
    Piecewise _ conditionArg branches -> conditionArg : branches
    Rotate _ arg -> [arg]
    ReFT arg -> [arg]
    ImFT arg -> [arg]
    TwiceReFT arg -> [arg]
    TwiceImFT arg -> [arg]

-- | Retrieve a 'Op' from it's base 'ExpressionMap' and 'NodeID'
{-# INLINE retrieveOp #-}
retrieveOp :: HasCallStack => NodeID -> ExpressionMap -> Op
retrieveOp n mp =
  case IM.lookup n mp of
    Just (_, _, op) -> op
    _ -> error "node not in map"

-- | Retrieve a 'Node' structure (i.e a 'Node' with it's 'Shape') from it's base 'ExpressionMap' and 'NodeID'
{-# INLINE retrieveNode #-}
retrieveNode :: HasCallStack => NodeID -> ExpressionMap -> Node
retrieveNode n mp =
  case IM.lookup n mp of
    Just internal -> internal
    _ -> error "node not in map"

-- | Retrieve the ElementType (i.e 'R','C','Covector') of a 'Node' from it's base 'ExpressionMap' and 'NodeID'
{-# INLINE retrieveElementType #-}
retrieveElementType :: HasCallStack => NodeID -> ExpressionMap -> ET
retrieveElementType n mp =
  case IM.lookup n mp of
    Just (_, et, _) -> et
    _ -> error "expression not in map"

-- | Retrieve the 'Shape' of a 'Node' from it's base 'ExpressionMap' and 'NodeID'
{-# INLINE retrieveShape #-}
retrieveShape :: HasCallStack => NodeID -> ExpressionMap -> Shape
retrieveShape n mp =
  case IM.lookup n mp of
    Just (shape, _, _) -> shape
    _ -> error "expression not in map"

-- | Retrieve the 'ElementType' (i.e 'R','C','Covector') of a 'Expression'
{-# INLINE expressionElementType #-}
expressionElementType :: HasCallStack => Expression d et -> ET
expressionElementType (Expression n mp) =
  case IM.lookup n mp of
    Just (_, et, _) -> et
    _ -> error "expression not in map"

-- | Retrieve the 'Shape' of an 'Expression'
{-# INLINE expressionShape #-}
expressionShape :: HasCallStack => Expression d et -> Shape
expressionShape (Expression n mp) =
  case IM.lookup n mp of
    Just (dim, _, _) -> dim
    _ -> error "expression not in map"

-- | Retrieve the 'Node' of an 'Expression'
{-# INLINE expressionNode #-}
expressionNode :: HasCallStack => Expression d et -> Node
expressionNode (Expression n mp) =
  case IM.lookup n mp of
    Just internal -> internal
    _ -> error "expression not in map"

-- | Retrieve the Op of an expression
{-# INLINE expressionOp #-}
expressionOp :: HasCallStack => Expression d et -> Op
expressionOp (Expression n mp) =
  case IM.lookup n mp of
    Just (_, _, op) -> op
    _ -> error "expression not in map"
