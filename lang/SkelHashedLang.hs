module SkelHashedLang where

-- Haskell module generated by the BNF converter

import AbsHashedLang
import ErrM
type Result = Err String

failure :: Show a => a -> Result
failure x = Bad $ "Undefined case: " ++ show x

transKWDataPattern :: KWDataPattern -> Result
transKWDataPattern x = case x of
  KWDataPattern string -> failure x
transTokenSub :: TokenSub -> Result
transTokenSub x = case x of
  TokenSub string -> failure x
transTokenPlus :: TokenPlus -> Result
transTokenPlus x = case x of
  TokenPlus string -> failure x
transTokenReIm :: TokenReIm -> Result
transTokenReIm x = case x of
  TokenReIm string -> failure x
transTokenMul :: TokenMul -> Result
transTokenMul x = case x of
  TokenMul string -> failure x
transTokenDiv :: TokenDiv -> Result
transTokenDiv x = case x of
  TokenDiv string -> failure x
transTokenScale :: TokenScale -> Result
transTokenScale x = case x of
  TokenScale string -> failure x
transTokenDot :: TokenDot -> Result
transTokenDot x = case x of
  TokenDot string -> failure x
transTokenPower :: TokenPower -> Result
transTokenPower x = case x of
  TokenPower string -> failure x
transTokenRotate :: TokenRotate -> Result
transTokenRotate x = case x of
  TokenRotate string -> failure x
transTokenCase :: TokenCase -> Result
transTokenCase x = case x of
  TokenCase string -> failure x
transPInteger :: PInteger -> Result
transPInteger x = case x of
  PInteger string -> failure x
transPDouble :: PDouble -> Result
transPDouble x = case x of
  PDouble string -> failure x
transPUnaryFun :: PUnaryFun -> Result
transPUnaryFun x = case x of
  PUnaryFun string -> failure x
transPDoubleFun :: PDoubleFun -> Result
transPDoubleFun x = case x of
  PDoubleFun string -> failure x
transPIdent :: PIdent -> Result
transPIdent x = case x of
  PIdent string -> failure x
transProblem :: Problem -> Result
transProblem x = case x of
  Problem blocks -> failure x
transBlock :: Block -> Result
transBlock x = case x of
  BlockVariable variabledeclss -> failure x
  BlockConstant constantdeclss -> failure x
  BlockConstraint constraintdeclss -> failure x
  BlockLet letdeclss -> failure x
  BlockMinimize exp -> failure x
transTInt :: TInt -> Result
transTInt x = case x of
  IntPos pinteger -> failure x
  IntNeg tokensub pinteger -> failure x
transTDouble :: TDouble -> Result
transTDouble x = case x of
  DoublePos pdouble -> failure x
  DoubleNeg tokensub pdouble -> failure x
transNumber :: Number -> Result
transNumber x = case x of
  NumInt tint -> failure x
  NumDouble tdouble -> failure x
transVal :: Val -> Result
transVal x = case x of
  ValFile string -> failure x
  ValDataset string1 string2 -> failure x
  ValPattern kwdatapattern -> failure x
  ValRandom -> failure x
  ValLiteral number -> failure x
transDim :: Dim -> Result
transDim x = case x of
  Dim pinteger -> failure x
transShape :: Shape -> Result
transShape x = case x of
  ShapeScalar -> failure x
  Shape1D dim -> failure x
  Shape2D dim1 dim2 -> failure x
  Shape3D dim1 dim2 dim3 -> failure x
transVariableDecl :: VariableDecl -> Result
transVariableDecl x = case x of
  VariableNoInit pident shape -> failure x
  VariableWithInit pident shape val -> failure x
transConstantDecl :: ConstantDecl -> Result
transConstantDecl x = case x of
  ConstantDecl pident shape val -> failure x
transLetDecl :: LetDecl -> Result
transLetDecl x = case x of
  LetDecl pident exp -> failure x
transBound :: Bound -> Result
transBound x = case x of
  ConstantBound pident -> failure x
  NumberBound number -> failure x
transConstraintDecl :: ConstraintDecl -> Result
transConstraintDecl x = case x of
  ConstraintLower exp bound -> failure x
  ConstraintUpper exp bound -> failure x
  ConstraintEqual exp bound -> failure x
transRotateAmount :: RotateAmount -> Result
transRotateAmount x = case x of
  RA1D tint -> failure x
  RA2D tint1 tint2 -> failure x
  RA3D tint1 tint2 tint3 -> failure x
transPiecewiseCase :: PiecewiseCase -> Result
transPiecewiseCase x = case x of
  PiecewiseCase number exp -> failure x
  PiecewiseFinalCase exp -> failure x
transExp :: Exp -> Result
transExp x = case x of
  EPlus exp1 tokenplus exp2 -> failure x
  ERealImag exp1 tokenreim exp2 -> failure x
  ESubtract exp1 tokensub exp2 -> failure x
  EMul exp1 tokenmul exp2 -> failure x
  EDiv exp1 tokendiv exp2 -> failure x
  EScale exp1 tokenscale exp2 -> failure x
  EDot exp1 tokendot exp2 -> failure x
  EPower exp tokenpower tint -> failure x
  EUnaryFun punaryfun exp -> failure x
  EDoubleFun pdoublefun number exp -> failure x
  ERotate tokenrotate rotateamount exp -> failure x
  ENegate tokensub exp -> failure x
  ENumDouble pdouble -> failure x
  ENumInteger pinteger -> failure x
  EIdent pident -> failure x
  EPiecewise tokencase exp piecewisecases -> failure x

