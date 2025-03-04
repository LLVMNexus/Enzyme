; RUN: if [ %llvmver -lt 16 ]; then %opt < %s %loadEnzyme -enzyme-preopt=false -enzyme -S | FileCheck %s; fi
; RUN: %opt < %s %newLoadEnzyme -enzyme-preopt=false -passes="enzyme" -S | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v32:32:32-v64:64:64-v128:128:128-n16:32:64-ni:10:11:12:13"
target triple = "nvptx64-nvidia-cuda"

declare float @llvm.nvvm.ldg.global.f.f32.p1f32(float addrspace(1)* nocapture, i32)

define float @vmul(float addrspace(1)* %inp) {
top:
  %ld = call float @llvm.nvvm.ldg.global.f.f32.p1f32(float addrspace(1)* %inp, i32 4)
  ret float %ld
}


define float @test_derivative(float addrspace(1)* %inp, float addrspace(1)* %dinp) {
entry:
  %0 = tail call float (float (float addrspace(1)*)*, ...) @__enzyme_fwddiff(float (float addrspace(1)*)* nonnull @vmul, float addrspace(1)* %inp, float addrspace(1)* %dinp)
  ret float %0
}

; Function Attrs: nounwind
declare float @__enzyme_fwddiff(float (float addrspace(1)*)*, ...)

; CHECK: define internal float @fwddiffevmul(float addrspace(1)* %inp, float addrspace(1)* %"inp'")
; CHECK-NEXT: top:
; CHECK-NEXT:   %[[res:.+]] = call{{( fast)?}} float @llvm.nvvm.ldg.global.f.f32.p1f32(float addrspace(1)* %"inp'", i32 4)
; CHECK-NEXT:   ret float %[[res]]
; CHECK-NEXT: }