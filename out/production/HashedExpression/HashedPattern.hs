{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiWayIf #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}

-------------------------------------------------------------------------------
-- |
-- (c) 2014 Christopher Kumar Anand
-- Helper functions/instances to make pattern gaurds involving Expressions
-- easier to read.
--
-------------------------------------------------------------------------------
module HashedPattern where

import qualified Data.IntMap.Strict as IM
import Data.List.HT (splitLast, viewR)
import Data.Map (Map, union)
import qualified Data.Map.Strict as Map
import Data.Maybe
import Debug.Trace (trace, traceShowId)
import HashedExpression
import HashedInner
import HashedInner
import HashedNode
import HashedOperation
import HashedUtils
import qualified Prelude
import Prelude hiding
    ( (*)
    , (+)
    , (-)
    , (/)
    , (^)
    , acos
    , acosh
    , asin
    , asinh
    , atan
    , atanh
    , const
    , cos
    , cosh
    , exp
    , negate
    , product
    , sin
    , sinh
    , sum
    , tan
    , tanh
    )
import Prelude (Bool)
import Prelude (Bool)

-- | Pattern for simplification
--
type Capture = Int

type ListCapture = Int

-- | List holes to captures many elements
--
data PatternList =
    PListHole (Pattern -> Pattern) ListCapture
    deriving (Show)

instance Show (Pattern -> Pattern) where
    show p = "(Pattern -> Pattern)"

-- |
--
data Pattern
    = PHole Capture
    -- Ref to a node in the expression
    | PRef Int
    -- Ref to head of the list captures e.g:
    -- ListCapture(2) -> [2132, 34512, 4542],
    -- PHead (transformation) 2 ---> transformation 2132
    | PHead (Pattern -> Pattern) ListCapture
    -- MARK: For list capture
    | PSumList PatternList
    -- MARK: Reflex Node in HashedExpression
    | PConst Double
    | PScalarConst Double -- Pattern for scalar const used in RHS
    | PSum [Pattern]
    | PMul [Pattern]
    | PNeg Pattern
    | PScale Pattern Pattern
    | PDiv Pattern Pattern
    | PSqrt Pattern
    | PSin Pattern
    | PCos Pattern
    | PTan Pattern
    | PExp Pattern
    | PLog Pattern
    | PSinh Pattern
    | PCosh Pattern
    | PTanh Pattern
    | PAsin Pattern
    | PAcos Pattern
    | PAtan Pattern
    | PAsinh Pattern
    | PAcosh Pattern
    | PAtanh Pattern
    | PRealImag Pattern Pattern
    | PRealPart Pattern
    | PImagPart Pattern
    | PInnerProd Pattern Pattern
    | PPiecewise Pattern PatternList
    | PMulRest ListCapture [Pattern]
    | PSumRest ListCapture [Pattern]
    | PPower Pattern Pattern
    | PRotate [Pattern] Pattern
    deriving (Show)

-- |
--
infixl 7 ~*

infixl 6 ~+

class MulRestOp a b c | a b -> c where
    (~*) :: a -> b -> c

instance MulRestOp Pattern Pattern Pattern where
    (~*) (PMulRest listCapture ps) p = PMulRest listCapture (ps ++ [p])

instance MulRestOp Pattern PatternList PatternList where
    (~*) rest (PListHole fs listHole) = PListHole ((rest ~*) . fs) listHole

class SumRestOp a b c | a b -> c where
    (~+) :: a -> b -> c

instance SumRestOp Pattern Pattern Pattern where
    (~+) (PSumRest listCapture ps) p = PSumRest listCapture (ps ++ [p])

instance SumRestOp Pattern PatternList PatternList where
    (~+) rest (PListHole fs listHole) = PListHole ((rest ~+) . fs) listHole

-- | Pattern
--
instance AddableOp Pattern where
    (+) wh1 wh2 = PSum [wh1, wh2]
    negate = PNeg

instance MultiplyOp Pattern Pattern Pattern where
    (*) wh1 wh2 = PMul [wh1, wh2]

instance VectorSpaceOp Pattern Pattern where
    scale = PScale

instance NumOp Pattern where
    sqrt = PSqrt
    exp = PExp
    log = PLog
    sin = PSin
    cos = PCos
    tan = PTan
    asin = PAsin
    acos = PAcos
    atan = PAtan
    sinh = PSinh
    cosh = PCosh
    tanh = PTanh
    asinh = PAsinh
    acosh = PAcosh
    atanh = PAtanh
    (/) = PDiv


instance ComplexRealOp Pattern Pattern where
    (+:) = PRealImag
    xRe = PRealPart
    xIm = PImagPart

instance InnerProductSpaceOp Pattern Pattern Pattern where
    (<.>) = PInnerProd

instance PowerOp Pattern Pattern where
    (^) = PPower

-- | Pattern List
--
instance AddableOp PatternList where
    (+) = error "Not implementation for adding two pattern list yet"
    negate (PListHole f listCapture) = PListHole (negate . f) listCapture

instance MultiplyOp Pattern PatternList PatternList where
    (*) wh1 (PListHole f listCapture) = PListHole ((wh1 *) . f) listCapture

instance MultiplyOp PatternList Pattern PatternList where
    (*) (PListHole f listCapture) wh2 = PListHole ((* wh2) . f) listCapture

instance InnerProductSpaceOp Pattern PatternList PatternList where
    (<.>) wh1 (PListHole f listCapture) = PListHole ((wh1 <.>) . f) listCapture

instance InnerProductSpaceOp PatternList Pattern PatternList where
    (<.>) (PListHole f listCapture) wh2 = PListHole ((<.> wh2) . f) listCapture

instance VectorSpaceOp Pattern PatternList where
    scale wh1 (PListHole f listCapture) =
        PListHole ((wh1 `scale`) . f) listCapture

-- | Guarded patterns for simplification
--
data GuardedPattern =
    GP Pattern Condition

type Substitution = (GuardedPattern, Pattern)

-- | Helper to make pattern and replacement without condition
--
(|.~~~~~~>) :: Pattern -> Pattern -> Substitution
(|.~~~~~~>) pattern replacement =
    (GP pattern $ Prelude.const (Prelude.const True), replacement)

infix 0 |.~~~~~~>, ~~~~~~>

(~~~~~~>) :: GuardedPattern -> Pattern -> Substitution
(~~~~~~>) gPattern replacement = (gPattern, replacement)

(|.) :: Pattern -> Condition -> GuardedPattern
(|.) pattern condition = GP pattern condition

infixl 1 |.

type Condition = (ExpressionMap, Int) -> Match -> Bool

-- |
--
(&&.) :: Condition -> Condition -> Condition
(&&.) condition1 condition2 expr match =
    condition1 expr match && condition2 expr match

-- |
--
isNot :: Condition -> Condition
isNot condition expr match = not $ condition expr match

infixl 8 &&.

-- |
--
(||.) :: Condition -> Condition -> Condition
(||.) condition1 condition2 expr match =
    condition1 expr match || condition2 expr match

-- |
--
isScalar :: Pattern -> Condition
isScalar p exp match =
    let ExpressionDiff extraEntries newRootId = buildFromPattern exp match p
        originMp = fst exp
     in retrieveShape newRootId (IM.union extraEntries originMp) == []

-- |
--
isConst :: Pattern -> Condition
isConst p exp match =
    let ExpressionDiff extraEntries newRootId = buildFromPattern exp match p
        originMp = fst exp
     in case retrieveNode newRootId (IM.union extraEntries originMp) of
            Const _ -> True
            _ -> False

-- |
--
isNotConst :: Pattern -> Condition
isNotConst p exp match = not $ isConst p exp match

-- |
--
isReal :: Pattern -> Condition
isReal p exp match =
    let ExpressionDiff extraEntries newRootId = buildFromPattern exp match p
        originMp = fst exp
     in retrieveElementType newRootId (IM.union extraEntries originMp) == R

-- |
--
isComplex :: Pattern -> Condition
isComplex p exp match =
    let ExpressionDiff extraEntries newRootId = buildFromPattern exp match p
        originMp = fst exp
     in retrieveElementType newRootId (IM.union extraEntries originMp) == C

-- |
--
sameElementType :: [Pattern] -> Condition
sameElementType ps exp match = allEqual . map getET $ ps
  where
    getET p =
        let ExpressionDiff extraEntries newRootId = buildFromPattern exp match p
            originMp = fst exp
         in retrieveElementType newRootId (IM.union extraEntries originMp)

-- |
--
allTheSame :: PatternList -> Condition
allTheSame pl@(PListHole _ listCapture) exp match
    | Just nIds <- Map.lookup listCapture . listCapturesMap $ match =
        allEqual nIds
    | otherwise = False

-- |
--
[p, q, r, s, t, u, v, w, x, y, z, condition] = map PHole [1 .. 12]

one :: Pattern
one = PConst 1

zero :: Pattern
zero = PConst 0

scalarOne :: Pattern
scalarOne = PScalarConst 1

scalarZero :: Pattern
scalarZero = PScalarConst 0

num :: Double -> Pattern
num = PConst

each :: PatternList
each = PListHole id 1

sumOf :: PatternList -> Pattern
sumOf = PSumList

-- |
--
piecewise :: Pattern -> PatternList -> Pattern
piecewise = PPiecewise

branches :: PatternList
branches = PListHole id 2

headOf :: PatternList -> Pattern
headOf (PListHole trans listCapture) = PHead trans listCapture

-- |
--
restOfProduct :: Pattern
restOfProduct = PMulRest 239 []

restOfSum :: Pattern
restOfSum = PSumRest 2391 []

-- | Matches all nodes in the expression to see if they all match the PatternList, if they match, return
-- the inner actual nodes
-- e.g: matchList [a + (b * x), a + (b * y), a + (b * z)] (PatternList: (a + (b * _)) ---> Just [x, y, z]
--      matchList [x, y, z, t] (PatternList: (_)) = Just [x, y, z, t]
--      matchList [1 + x, 2 + x, y + x] (PatternList: (a + _)) = Nothing (not the same for all)
--
matchList :: ExpressionMap -> [Int] -> PatternList -> Maybe [Int]
matchList mp ns (PListHole fs listCapture)
    | all isJust maybeSubMatches
    , let subMatches = catMaybes maybeSubMatches
    , allEqual $ map otherCaptures subMatches = Just $ nIds subMatches
    | otherwise = Nothing
  where
    uniqueCapture = minBound :: Int
    eachHole = PHole uniqueCapture
    pt = fs eachHole
    matchOne nId = match (mp, nId) pt
    maybeSubMatches = map matchOne ns
    otherCaptures = Map.delete uniqueCapture . capturesMap
    nIds subMatches =
        catMaybes . map (Map.lookup uniqueCapture . capturesMap) $ subMatches

data Match =
    Match
        { capturesMap :: Map Capture Int
        , listCapturesMap :: Map ListCapture [Int]
        }
    deriving (Show)

unionMatch :: Match -> Match -> Match
unionMatch match1 match2 =
    Match
        (capturesMap match1 `union` capturesMap match2)
        (listCapturesMap match1 `union` listCapturesMap match2)

-- | Match an expression with a pattern, return the map between capture hole to the actual node
-- e.g: match (Expression: (a(3243) + b(32521)) (PatternNormal:(x(1) + y(2)) --> ({1 -> 3243, 2 -> 32521}, {})
--      match (Expression sum(a(3243), b(32521), c(21321)) (PatternNormal:(sum(each(1))) --> ({}, {1 -> [3243, 32521, 21321]})
match :: (ExpressionMap, Int) -> Pattern -> Maybe Match
match (mp, n) outerWH =
    let unionBoth (x1, y1) (x2, y2) = (x1 `union` x2, y1 `union` y2)
        catMatch = foldl unionMatch (Match Map.empty Map.empty)
        recursiveAndCombine :: [Arg] -> [Pattern] -> Maybe Match
        recursiveAndCombine args whs
            | length args == length whs
            , let subMatches = zipWith match (map (mp, ) args) whs
            , all isJust subMatches = Just . catMatch . catMaybes $ subMatches
            | otherwise = Nothing
     in case (retrieveNode n mp, outerWH) of
            (_, PHole capture) ->
                Just $ Match (Map.fromList [(capture, n)]) Map.empty
            (Const c, PConst whc)
                | c == whc -> Just $ Match Map.empty Map.empty
            (Sum _ args, PSum whs) -> recursiveAndCombine args whs
            (Sum _ args, PSumList pl@(PListHole _ listCapture))
                | Just innerArgs <- matchList mp args pl ->
                    Just $
                    Match Map.empty (Map.fromList [(listCapture, innerArgs)])
            (Sum _ args, PSumRest listCapture ps)
                | length args > length ps
                , let (rest, normalParts) =
                          splitAt (length args - length ps) args
                , length normalParts == length ps
                , Just matchNormalParts <- recursiveAndCombine normalParts ps
                , let matchListPart =
                          Match Map.empty (Map.fromList [(listCapture, rest)]) ->
                    Just $ unionMatch matchNormalParts matchListPart
            (Mul _ args, PMul whs) -> recursiveAndCombine args whs
            (Mul _ args, PMulRest listCapture ps)
                | length args > (length ps)
                , let (rest, normalParts) =
                          splitAt (length args - length ps) args
                , length normalParts == length ps
                , Just matchNormalParts <- recursiveAndCombine normalParts ps
                , let matchListPart =
                          Match Map.empty (Map.fromList [(listCapture, rest)]) ->
                    Just $ unionMatch matchNormalParts matchListPart
            (Neg _ arg, PNeg wh) -> recursiveAndCombine [arg] [wh]
            (Scale _ arg1 arg2, PScale wh1 wh2) ->
                recursiveAndCombine [arg1, arg2] [wh1, wh2]
            (Div arg1 arg2, PDiv wh1 wh2) ->
                recursiveAndCombine [arg1, arg2] [wh1, wh2]
            (Sqrt arg, PSqrt wh) -> recursiveAndCombine [arg] [wh]
            (Sin arg, PSin wh) -> recursiveAndCombine [arg] [wh]
            (Cos arg, PCos wh) -> recursiveAndCombine [arg] [wh]
            (Tan arg, PTan wh) -> recursiveAndCombine [arg] [wh]
            (Exp arg, PExp wh) -> recursiveAndCombine [arg] [wh]
            (Log arg, PLog wh) -> recursiveAndCombine [arg] [wh]
            (Sinh arg, PSinh wh) -> recursiveAndCombine [arg] [wh]
            (Cosh arg, PCosh wh) -> recursiveAndCombine [arg] [wh]
            (Tanh arg, PTanh wh) -> recursiveAndCombine [arg] [wh]
            (Asin arg, PAsin wh) -> recursiveAndCombine [arg] [wh]
            (Acos arg, PAcos wh) -> recursiveAndCombine [arg] [wh]
            (Atan arg, PAtan wh) -> recursiveAndCombine [arg] [wh]
            (Asinh arg, PAsinh wh) -> recursiveAndCombine [arg] [wh]
            (Acosh arg, PAcosh wh) -> recursiveAndCombine [arg] [wh]
            (Atanh arg, PAtanh wh) -> recursiveAndCombine [arg] [wh]
            (RealImag arg1 arg2, PRealImag wh1 wh2) ->
                recursiveAndCombine [arg1, arg2] [wh1, wh2]
            (RealPart arg, PRealPart wh) -> recursiveAndCombine [arg] [wh]
            (ImagPart arg, PImagPart wh) -> recursiveAndCombine [arg] [wh]
            (InnerProd _ arg1 arg2, PInnerProd wh1 wh2) ->
                recursiveAndCombine [arg1, arg2] [wh1, wh2]
            (Piecewise _ conditionArg branchArgs, PPiecewise wh pl@(PListHole _ listCapture))
                | Just innerArgs <- matchList mp branchArgs pl
                , Just (Match cMap lcMap) <-
                     recursiveAndCombine [conditionArg] [wh] ->
                    Just $
                    Match
                        cMap
                        (lcMap `union` (Map.fromList [(listCapture, innerArgs)]))
                | otherwise -> Nothing
            (Power x arg, PPower sp (PConst val))
                | fromIntegral x == val -> recursiveAndCombine [arg] [sp]
            _ -> Nothing

turnToPattern :: (Pattern -> Pattern) -> Int -> Pattern
turnToPattern fs nId = fs $ PRef nId

buildFromPatternList ::
       (ExpressionMap, Int) -> Match -> PatternList -> [ExpressionDiff]
buildFromPatternList exp match (PListHole fs listCapture)
    | Just ns <- Map.lookup listCapture (listCapturesMap match) =
        map (buildFromPattern exp match . turnToPattern fs) ns
    | otherwise =
        error
            "ListCapture not in the Map ListCapture [Int] which should never happens"

buildFromPattern :: (ExpressionMap, Int) -> Match -> Pattern -> ExpressionDiff
buildFromPattern exp@(originalMp, originalN) match = buildFromPattern'
  where
    applyDiff' = applyDiff originalMp
    buildFromPattern' :: Pattern -> ExpressionDiff
    buildFromPattern' pattern =
        case pattern of
            PRef nId -> withoutExtraEntry nId
            PHole capture
                | Just nId <- Map.lookup capture (capturesMap match) ->
                    withoutExtraEntry nId
                | otherwise ->
                    error
                        "Capture not in the Map Capture Int which should never happens"
            PHead fs listCapture
                | Just ns <- Map.lookup listCapture (listCapturesMap match)
                , let pt = turnToPattern fs . head $ ns -> buildFromPattern' pt
                | otherwise ->
                    error
                        "ListCapture not in the Map ListCapture [Int] which should never happens"
            PConst val -> diffConst (retrieveShape originalN originalMp) val
            PScalarConst val -> diffConst [] val
            PSumList ptl ->
                sumManyDiff originalMp . buildFromPatternList exp match $ ptl
            PSum sps -> sumManyDiff originalMp . map buildFromPattern' $ sps
            PMul sps -> mulManyDiff originalMp . map buildFromPattern' $ sps
            PNeg sp ->
                applyDiff' (unaryET Neg ElementDefault) [buildFromPattern' sp]
            PScale sp1 sp2 ->
                applyDiff' (binaryET Scale ElementDefault) $
                map buildFromPattern' [sp1, sp2]
            PDiv sp1 sp2 ->
                applyDiff' (binary Div) $ map buildFromPattern' [sp1, sp2]
            PSqrt sp -> applyDiff' (unary Sqrt) [buildFromPattern' sp]
            PSin sp -> applyDiff' (unary Sin) [buildFromPattern' sp]
            PCos sp -> applyDiff' (unary Cos) [buildFromPattern' sp]
            PTan sp -> applyDiff' (unary Tan) [buildFromPattern' sp]
            PExp sp -> applyDiff' (unary Exp) [buildFromPattern' sp]
            PLog sp -> applyDiff' (unary Log) [buildFromPattern' sp]
            PSinh sp -> applyDiff' (unary Sinh) [buildFromPattern' sp]
            PCosh sp -> applyDiff' (unary Cosh) [buildFromPattern' sp]
            PTanh sp -> applyDiff' (unary Tanh) [buildFromPattern' sp]
            PAsin sp -> applyDiff' (unary Asin) [buildFromPattern' sp]
            PAcos sp -> applyDiff' (unary Acos) [buildFromPattern' sp]
            PAtan sp -> applyDiff' (unary Atan) [buildFromPattern' sp]
            PAsinh sp -> applyDiff' (unary Asinh) [buildFromPattern' sp]
            PAcosh sp -> applyDiff' (unary Acosh) [buildFromPattern' sp]
            PAtanh sp -> applyDiff' (unary Atanh) [buildFromPattern' sp]
            PRealImag sp1 sp2 ->
                applyDiff' (binary RealImag) $ map buildFromPattern' [sp1, sp2]
            PRealPart sp -> applyDiff' (unary RealPart) [buildFromPattern' sp]
            PImagPart sp -> applyDiff' (unary ImagPart) [buildFromPattern' sp]
            PInnerProd sp1 sp2 ->
                applyDiff' (binaryET InnerProd ElementDefault `hasShape` []) $
                map buildFromPattern' [sp1, sp2]
            PPiecewise _ _ ->
                error
                    "Pattern piecewise appear on the right side of simplification rules which we haven't had yet"
            PMulRest restCapture sps
                | Just ns <- Map.lookup restCapture (listCapturesMap match) ->
                    mulManyDiff originalMp $
                    (map withoutExtraEntry ns) ++ map (buildFromPattern') sps
            PSumRest restCapture sps
                | Just ns <- Map.lookup restCapture (listCapturesMap match) ->
                    sumManyDiff originalMp $
                    (map withoutExtraEntry $ ns) ++ map (buildFromPattern') sps
            _ ->
                error
                    "The right hand-side of substitution has something that we don't support yet"