{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DuplicateRecordFields #-}

module HashedExpression.Internal.OperationSpec where

import Data.List (sort)
import GHC.Stack (HasCallStack)
import HashedExpression.Internal.Expression
import HashedExpression.Internal.Utils

data UnarySpec = UnarySpec
  { toOp :: Arg -> Op,
    decideShape :: Shape -> Shape,
    decideET :: ET -> ET
  }

data BinarySpec = BinarySpec
  { toOp :: Arg -> Arg -> Op,
    decideShape :: Shape -> Shape -> Shape,
    decideET :: ET -> ET -> ET
  }

data NarySpec = NarySpec
  { toOp :: [Arg] -> Op,
    decideShape :: [Shape] -> Shape,
    decideET :: [ET] -> ET
  }

data ConditionarySpec = ConditionarySpec
  { toOp :: Arg -> [Arg] -> Op,
    decideShape :: Shape -> [Shape] -> Shape,
    decideET :: ET -> [ET] -> ET
  }

data OperationSpec
  = Unary UnarySpec
  | Binary BinarySpec
  | Nary NarySpec
  | ConditionAry ConditionarySpec

-------------------------------------------------------------------------------
assertSame :: (HasCallStack, Ord a, Show a) => [a] -> b -> b
assertSame xs y
  | allEqual xs = y
  | otherwise = error $ "must be equal " ++ show xs

-------------------------------------------------------------------------------

-- |
defaultUnary :: HasCallStack => (Arg -> Op) -> [ET] -> UnarySpec
defaultUnary f allowedETs = UnarySpec {toOp = f, decideShape = id, decideET = decideET}
  where
    decideET et
      | et `elem` allowedETs = et
      | otherwise = error "Element type is not allowed"

-- |
defaultBinary :: HasCallStack => (Arg -> Arg -> Op) -> [ET] -> BinarySpec
defaultBinary f allowedETs = BinarySpec {toOp = f, decideShape = req, decideET = decideET}
  where
    req x y = assertSame [x, y] x
    decideET x y
      | x `elem` allowedETs = assertSame [x, y] x
      | otherwise = error "Element type is not allowed"

-------------------------------------------------------------------------------

specSum :: HasCallStack => NarySpec
specSum =
  NarySpec
    { toOp = Sum,
      decideShape = \xs -> assertSame xs $ head xs,
      decideET = \xs -> assertSame xs $ head xs
    }

specMul :: HasCallStack => NarySpec
specMul =
  NarySpec
    { toOp = Mul,
      decideShape = \xs -> assertSame xs $ head xs,
      decideET = \xs -> assertSame xs $ head xs
    }

specPower :: HasCallStack => Int -> UnarySpec
specPower alpha = defaultUnary (Power alpha) [R, C]

specNeg :: HasCallStack => UnarySpec
specNeg = defaultUnary Neg [R, C, Covector]

specScale :: HasCallStack => BinarySpec
specScale =
  BinarySpec
    { toOp = Scale,
      decideShape = decideShape,
      decideET = decideET
    }
  where
    decideShape x y
      | null x = y
      | otherwise = error "First operand must be scalar"
    decideET :: ET -> ET -> ET
    decideET R R = R
    decideET R C = C
    decideET C C = C
    decideET x y = error $ "Scaling invalid et " ++ show x ++ " " ++ show y

specDiv :: HasCallStack => BinarySpec
specDiv = defaultBinary Div [R]

specSqrt :: HasCallStack => UnarySpec
specSqrt = defaultUnary Sqrt [R]

specSin :: HasCallStack => UnarySpec
specSin = defaultUnary Sin [R]

specCos :: HasCallStack => UnarySpec
specCos = defaultUnary Cos [R]

specTan :: HasCallStack => UnarySpec
specTan = defaultUnary Tan [R]

specExp :: HasCallStack => UnarySpec
specExp = defaultUnary Exp [R]

specLog :: HasCallStack => UnarySpec
specLog = defaultUnary Log [R]

specSinh :: HasCallStack => UnarySpec
specSinh = defaultUnary Sinh [R]

specCosh :: HasCallStack => UnarySpec
specCosh = defaultUnary Cosh [R]

specTanh :: HasCallStack => UnarySpec
specTanh = defaultUnary Tanh [R]

specAsin :: HasCallStack => UnarySpec
specAsin = defaultUnary Asin [R]

specAcos :: HasCallStack => UnarySpec
specAcos = defaultUnary Acos [R]

specAtan :: HasCallStack => UnarySpec
specAtan = defaultUnary Atan [R]

specAsinh :: HasCallStack => UnarySpec
specAsinh = defaultUnary Asinh [R]

specAcosh :: HasCallStack => UnarySpec
specAcosh = defaultUnary Acosh [R]

specAtanh :: HasCallStack => UnarySpec
specAtanh = defaultUnary Atanh [R]

specRealImag :: HasCallStack => BinarySpec
specRealImag =
  BinarySpec {toOp = RealImag, decideShape = decideShape, decideET = decideET}
  where
    decideShape x y = assertSame [x, y] x
    decideET x y
      | x == R && y == R = C
      | otherwise = error $ "2 operands must be real" ++ show [x, y]

specRealPart :: HasCallStack => UnarySpec
specRealPart =
  UnarySpec {toOp = RealPart, decideShape = id, decideET = decideET}
  where
    decideET x
      | x == C = R
      | otherwise = error "Must be complex"

specImagPart :: HasCallStack => UnarySpec
specImagPart =
  UnarySpec {toOp = ImagPart, decideShape = id, decideET = decideET}
  where
    decideET x
      | x == C = R
      | otherwise = error "Must be complex"

specConjugate :: HasCallStack => UnarySpec
specConjugate = defaultUnary Conjugate [C]

specInnerProd :: HasCallStack => BinarySpec
specInnerProd =
  BinarySpec
    { toOp = InnerProd,
      decideShape = decideShape,
      decideET = decideET
    }
  where
    decideShape x y = assertSame [x, y] []
    decideET x y = assertSame [x, y] x

specPiecewise :: HasCallStack => [Double] -> ConditionarySpec
specPiecewise marks =
  ConditionarySpec {toOp = Piecewise marks, decideShape = decideShape, decideET = decideET}
  where
    decideShape condition branches = assertSame (condition : branches) condition
    decideET condition branches
      | condition == R && length branches == length marks + 1 = head branches
      | otherwise = error "Condition must be real and number of branches must equal number of marks + 1"

specRotate :: HasCallStack => RotateAmount -> UnarySpec
specRotate ra = defaultUnary (Rotate ra) [R, C, Covector]

specReFT :: HasCallStack => UnarySpec
specReFT =
  UnarySpec {toOp = ReFT, decideShape = id, decideET = decideET}
  where
    decideET x
      | x == R || x == C = R
      | x == Covector = Covector

specImFT :: HasCallStack => UnarySpec
specImFT =
  UnarySpec {toOp = ImFT, decideShape = id, decideET = decideET}
  where
    decideET x
      | x == R || x == C = R
      | x == Covector = Covector

specTwiceReFT :: HasCallStack => UnarySpec
specTwiceReFT =
  UnarySpec {toOp = TwiceReFT, decideShape = id, decideET = decideET}
  where
    decideET x
      | x == R || x == C = R
      | x == Covector = Covector

specTwiceImFT :: HasCallStack => UnarySpec
specTwiceImFT =
  UnarySpec {toOp = TwiceImFT, decideShape = id, decideET = decideET}
  where
    decideET x
      | x == R || x == C = R
      | x == Covector = Covector

specMulD :: HasCallStack => BinarySpec
specMulD =
  BinarySpec {toOp = MulD, decideShape = \x y -> assertSame [x, y] x, decideET = decideET}
  where
    decideET R Covector = Covector
    decideET _ _ = error "Must be R * Covector"

specScaleD :: HasCallStack => BinarySpec
specScaleD =
  BinarySpec {toOp = ScaleD, decideShape = decideShape, decideET = decideET}
  where
    decideShape [] x = x
    decideShape _ _ = error "First operand must be scalar"
    decideET R Covector = Covector
    decideET _ _ = error "Must be R *. Covector"

specDScale :: HasCallStack => BinarySpec
specDScale =
  BinarySpec {toOp = DScale, decideShape = decideShape, decideET = decideET}
  where
    decideShape [] x = x
    decideShape _ _ = error "First operand must be scalar"
    decideET Covector R = Covector
    decideET _ _ = error "Must be Covector .* R"

specInnerProdD :: HasCallStack => BinarySpec
specInnerProdD =
  BinarySpec {toOp = InnerProdD, decideShape = decideShape, decideET = decideET}
  where
    decideShape x y = assertSame [x, y] []
    decideET R Covector = Covector
    decideET _ _ = error "Must be R <.> Covector"