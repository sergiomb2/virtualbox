; $Id$
;; @file
; IPRT - No-CRT log - AMD64 & X86.
;

;
; Copyright (C) 2006-2022 Oracle Corporation
;
; This file is part of VirtualBox Open Source Edition (OSE), as
; available from http://www.virtualbox.org. This file is free software;
; you can redistribute it and/or modify it under the terms of the GNU
; General Public License (GPL) as published by the Free Software
; Foundation, in version 2 as it comes in the "COPYING" file of the
; VirtualBox OSE distribution. VirtualBox OSE is distributed in the
; hope that it will be useful, but WITHOUT ANY WARRANTY of any kind.
;
; The contents of this file may alternatively be used under the terms
; of the Common Development and Distribution License Version 1.0
; (CDDL) only, as it comes in the "COPYING.CDDL" file of the
; VirtualBox OSE distribution, in which case the provisions of the
; CDDL are applicable instead of those of the GPL.
;
; You may elect to license modified versions of this file under the
; terms and conditions of either the GPL or the CDDL or both.
;


%define RT_ASM_WITH_SEH64
%include "iprt/asmdefs.mac"
%include "iprt/x86.mac"


BEGINCODE

;;
; compute the natural logarithm of rd
; @returns st(0) / xmm0
; @param    rd      [rbp + xCB*2] / xmm0
RT_NOCRT_BEGINPROC log
        push    xBP
        SEH64_PUSH_xBP
        mov     xBP, xSP
        SEH64_SET_FRAME_xBP 0
%ifdef RT_ARCH_AMD64
        sub     xSP, 10h
        SEH64_ALLOCATE_STACK 10h
%endif
        SEH64_END_PROLOGUE

        fldln2                              ; st0=log(2)
%ifdef RT_ARCH_AMD64
        movsd   [xBP - 10h], xmm0
        fld     qword [xBP - 10h]
%else
        fld     qword [xBP + xCB*2]         ; st1=log(2) st0=lrd
%endif
        fld     st0                         ; st1=log(2) st0=lrd st0=lrd
        fsub    qword [.one xWrtRIP]        ; st2=log(2) st1=lrd st0=lrd-1.0
        fld     st0                         ; st3=log(2) st2=lrd st1=lrd-1.0 st0=lrd-1.0

        fabs                                ; st3=log(2) st2=lrd st1=lrd-1.0 st0=abs(lrd-1.0)
        fcomp   qword [.limit xWrtRIP]      ; st2=log(2) st1=lrd st0=lrd-1.0
        fnstsw  ax
        and     eax, X86_FSW_C3 | X86_FSW_C2 | X86_FSW_C0
        jnz    .use_st1

        fstp    st0                         ; st1=log(2) st0=lrd
        fyl2x                               ; log(lrd)
        jmp     .done

.use_st1:
        fstp    st1                         ; st1=log(2) st0=lrd-1.0
        fyl2xp1                             ; log(lrd)

.done:
%ifdef RT_ARCH_AMD64
        fstp    qword [xBP - 10h]
        movsd   xmm0, [xBP - 10h]
%endif
        leave
        ret

ALIGNCODE(8)
.one:   dq  1.0
.limit: dq  0.29
ENDPROC   RT_NOCRT(log)
