; ModuleID = 'basic'
source_filename = "Main.hs"

define double @test23(double %w, double %x, double %y) {
entry:
  %t1142802484873426 = fmul double %x, %y
  %t818634733456307 = fadd double %w, %t1142802484873426
  ret double %t818634733456307
}

; Function Attrs: nounwind readnone speculatable
declare double @llvm.sin.f64(double) #0

; Function Attrs: nounwind readnone speculatable
declare double @llvm.cos.f64(double) #0

; Function Attrs: nounwind readnone
declare double @tan(double) #1

; Function Attrs: nounwind readnone
declare double @sinh(double) #1

; Function Attrs: nounwind readnone
declare double @cosh(double) #1

; Function Attrs: nounwind readnone
declare double @tanh(double) #1

; Function Attrs: nounwind readnone
declare double @asin(double) #1

; Function Attrs: nounwind readnone
declare double @acos(double) #1

; Function Attrs: nounwind readnone
declare double @atan(double) #1

; Function Attrs: nounwind readnone
declare double @asinh(double) #1

; Function Attrs: nounwind readnone
declare double @acosh(double) #1

; Function Attrs: nounwind readnone
declare double @atanh(double) #1

; Function Attrs: nounwind readnone speculatable
declare double @llvm.exp.f64(double) #0

; Function Attrs: nounwind readnone speculatable
declare double @llvm.log.f64(double) #0

; Function Attrs: nounwind readnone speculatable
declare double @llvm.pow.f64(double, double) #0

; Function Attrs: nounwind readnone speculatable
declare double @llvm.sqrt.f64(double) #0

attributes #0 = { nounwind readnone speculatable }
attributes #1 = { nounwind readnone }