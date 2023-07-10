// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build freebsd && (ppc64 || ppc64le)
// +build freebsd
// +build ppc64 ppc64le

// System calls and other sys.stuff for ppc64, FreeBSD

#include "go_asm.h"
#include "go_tls.h"
#include "textflag.h"
#include "asm_ppc64x.h"

#define CLOCK_REALTIME		0
#define CLOCK_MONOTONIC		4
#define FD_CLOEXEC		1
#define F_SETFD			2

#define SYS_exit			1
#define SYS_read			3
#define SYS_write			4
#define SYS_open			5
#define SYS_close			6
#define SYS_getpid			20
#define SYS_kill			37
#define SYS_sigaltstack			53
#define SYS_munmap			73
#define SYS_madvise			75
#define SYS_setitimer			83
#define SYS_fcntl			92
#define SYS___sysctl			202
#define SYS_nanosleep			240
#define SYS_clock_gettime		232
#define SYS_issetugid			253
#define SYS_sched_yield			331
#define SYS_sigprocmask			340
#define SYS_kqueue			362
#define SYS_sigaction			416
#define SYS_thr_exit			431
#define SYS_thr_self			432
#define SYS_thr_kill			433
#define SYS__umtx_op			454
#define SYS_thr_new			455
#define SYS_mmap			477
#define SYS_cpuset_getaffinity		487
#define SYS_pipe2 			542
#define SYS_kevent			560

TEXT emptyfunc<>(SB),0,$0-0
	RET

// XXX ret code
// func sys_umtx_op(addr *uint32, mode int32, val uint32, uaddr1 uintptr, ut *umtx_time) int32
TEXT runtime·sys_umtx_op(SB),NOSPLIT,$0
	MOVD	addr+0(FP), R3
	MOVW	mode+8(FP), R4
	MOVW	val+12(FP), R5
	MOVD	uaddr1+16(FP), R6
	MOVD	ut+24(FP), R7
	SYSCALL	$SYS__umtx_op
//	BVC	2(PC)
//	MOVW	$-1, R3
	MOVW	R3, ret+32(FP)
	RET

TEXT runtime·emptyfunc(SB),0,$0-0
	RET

TEXT runtime·thr_new(SB),NOSPLIT,$0
	MOVD	param+0(FP), R3
	MOVW	size+8(FP), R4
	SYSCALL	$SYS_thr_new
	BVC	2(PC)
	MOVW	$-1, R3
	MOVW	R3, ret+16(FP)
	RET

// ppc64 ELFv2 doesn't need function descriptors
TEXT runtime·thr_start(SB),NOSPLIT,$0
	// initialize essential registers (just in case)
	BL	runtime·reginit(SB)
	// set up g
	MOVD	m_g0(R3), g
	MOVD	R3, g_m(g)
	BL	emptyfunc<>(SB)  // fault if stack check is wrong
	BL	runtime·mstart(SB)

	MOVD	$2, R8  // crash (not reached)
	MOVD	R8, (R8)
	RET

// func exit(code int32)
TEXT runtime·exit(SB),NOSPLIT|NOFRAME,$0-4
	MOVW	code+0(FP), R3
	SYSCALL	$SYS_exit
	RET

// func exitThread(wait *uint32)
TEXT runtime·exitThread(SB),NOSPLIT|NOFRAME,$0-8
	MOVD	wait+0(FP), R1
	// We're done using the stack.
	MOVW	$0, R2
	SYNC
	MOVW	R2, (R1)
	MOVW	$0, R3	// exit code
	SYSCALL	$SYS_exit
	JMP	0(PC)

// func open(name *byte, mode, perm int32) int32
TEXT runtime·open(SB),NOSPLIT|NOFRAME,$0-20
	MOVD	name+0(FP), R3
	MOVW	mode+8(FP), R4
	MOVW	perm+12(FP), R5
	SYSCALL	$SYS_open
	BVC	2(PC)
	MOVW	$-1, R3
	MOVW	R3, ret+16(FP)
	RET

// func closefd(fd int32) int32
TEXT runtime·closefd(SB),NOSPLIT|NOFRAME,$0-12
	MOVW	fd+0(FP), R3
	SYSCALL	$SYS_close
	BVC	2(PC)
	MOVW	$-1, R3
	MOVW	R3, ret+8(FP)
	RET

// func pipe() (r, w int32, errno int32)
TEXT runtime·pipe(SB),NOSPLIT|NOFRAME,$0-12
	ADD	$FIXED_FRAME, R1, R3
	MOVW    $0, R4
	SYSCALL	$SYS_pipe2
	BVC	2(PC)
	MOVW	$-1, R3
	MOVW	R3, errno+8(FP)
	RET

// func pipe2(flags int32) (r, w int32, errno int32)
TEXT runtime·pipe2(SB),NOSPLIT|NOFRAME,$0-20
	ADD	$FIXED_FRAME+8, R1, R3
	MOVW	flags+0(FP), R4
	SYSCALL	$SYS_pipe2
	BVC	2(PC)
	MOVW	$-1, R3
	MOVW	R3, errno+16(FP)
	RET

// func write1(fd uintptr, p unsafe.Pointer, n int32) int32
TEXT runtime·write1(SB),NOSPLIT|NOFRAME,$0-28
	MOVD	fd+0(FP), R3
	MOVD	p+8(FP), R4
	MOVW	n+16(FP), R5
	SYSCALL	$SYS_write
	BVC	2(PC)
	MOVW	$-1, R3
	MOVW	R3, ret+24(FP)
	RET

// func read(fd int32, p unsafe.Pointer, n int32) int32
TEXT runtime·read(SB),NOSPLIT|NOFRAME,$0-28
	MOVW	fd+0(FP), R3
	MOVD	p+8(FP), R4
	MOVW	n+16(FP), R5
	SYSCALL	$SYS_read
	BVC	2(PC)
	MOVW	$-1, R3
	MOVW	R3, ret+24(FP)
	RET

// func usleep(usec uint32)
TEXT runtime·usleep(SB),NOSPLIT,$24-4
	MOVW	usec+0(FP), R3
	MOVD	R3, R5
	MOVW	$1000000, R4
	DIVD	R4, R3
	MOVD	R3, 8(R1)
	MULLD	R3, R4
	SUB	R4, R5
	MOVW	$1000, R4
	MULLD	R4, R5
	MOVD	R5, 16(R1)

	// nanosleep(&ts, 0)
	ADD	$8, R1, R3
	MOVD	$0, R4
	SYSCALL	$SYS_nanosleep
	RET

// func thr_self() thread
TEXT runtime·thr_self(SB),NOSPLIT|NOFRAME,$0-8
	MOVD	R3, R3
	SYSCALL $SYS_thr_self
	MOVD	R3, ret+0(FP)
	RET

// func thr_kill(t thread, sig int)
TEXT runtime·thr_kill(SB),NOSPLIT,$0-16
	MOVD    tid+0(FP), R3   // arg 1 id
	MOVD    sig+8(FP), R4   // arg 2 sig
	SYSCALL $SYS_thr_kill
	RET

// func raiseproc(sig uint32)
TEXT runtime·raiseproc(SB),NOSPLIT|NOFRAME,$0
	SYSCALL	$SYS_getpid
	MOVW	R3, R3	// arg 1 pid
	MOVW	sig+0(FP), R4	// arg 2
	SYSCALL	$SYS_kill
	RET

// func setitimer(mode int32, new, old *itimerval)
TEXT runtime·setitimer(SB),NOSPLIT|NOFRAME,$0-24
	MOVW	mode+0(FP), R3
	MOVD	new+8(FP), R4
	MOVD	old+16(FP), R5
	SYSCALL	$SYS_setitimer
	RET

// func fallback_walltime() (sec int64, nsec int32)
TEXT runtime·fallback_walltime(SB),NOSPLIT,$24-12
	MOVD	$CLOCK_REALTIME, R3
	MOVD	$8(R1), R4
	SYSCALL	$SYS_clock_gettime
	MOVD	8(R1), R3	// sec
	MOVD	16(R1), R5	// nsec
	MOVD	R3, sec+0(FP)
	MOVW	R5, nsec+8(FP)
	RET

// func fallback_nanotime() int64
TEXT runtime·fallback_nanotime(SB),NOSPLIT,$24-8
	MOVD	$CLOCK_MONOTONIC, R3
	MOVD	$8(R1), R4
	SYSCALL	$SYS_clock_gettime
	MOVD	8(R1), R3	// sec
	MOVD	16(R1), R5	// nsec

	// sec is in R3, nsec in R5
	// return nsec in R3
	MOVD	$1000000000, R4
	MULLD	R4, R3
	ADD	R5, R3

	MOVD	R3, ret+0(FP)
	RET

// func asmSigaction(sig uintptr, new, old *sigactiont) int32
TEXT runtime·asmSigaction(SB),NOSPLIT,$0
	MOVD	sig+0(FP), R3		// arg 1 sig
	MOVD	new+8(FP), R4		// arg 2 act
	MOVD	old+16(FP), R5		// arg 3 oact
	SYSCALL	$SYS_sigaction
	BVC	2(PC)
	MOVW	$-1, R3
	MOVW	R3, ret+24(FP)
	RET

// func sigfwd(fn uintptr, sig uint32, info *siginfo, ctx unsafe.Pointer)
TEXT runtime·sigfwd(SB),NOSPLIT,$0-32
	MOVW	sig+8(FP), R3
	MOVD	info+16(FP), R4
	MOVD	ctx+24(FP), R5
	MOVD	fn+0(FP), R12
	MOVD	R12, CTR
	BL	(CTR)
	MOVD	24(R1), R2
	RET

// func sigtramp()
// ppc64 ELFv2 doesn't need function descriptors
// Save callee-save registers in the case of signal forwarding.
// Same as on ARM64 https://golang.org/issue/31827 .
TEXT runtime·sigtramp(SB),NOSPLIT|NOFRAME,$0
	// Start with standard C stack frame layout and linkage.
	MOVD    LR, R0
	MOVD    R0, 16(R1) // Save LR in caller's frame.
	MOVW    CR, R0     // Save CR in caller's frame
	MOVD    R0, 8(R1)
	// The stack must be acquired here and not
	// in the automatic way based on stack size
	// since that sequence clobbers R31 before it
	// gets saved.
	// We are being ultra safe here in saving the
	// Vregs. The case where they might need to
	// be saved is very unlikely.
	MOVDU   R1, -544(R1)
	MOVD    R14, 64(R1)
	MOVD    R15, 72(R1)
	MOVD    R16, 80(R1)
	MOVD    R17, 88(R1)
	MOVD    R18, 96(R1)
	MOVD    R19, 104(R1)
	MOVD    R20, 112(R1)
	MOVD    R21, 120(R1)
	MOVD    R22, 128(R1)
	MOVD    R23, 136(R1)
	MOVD    R24, 144(R1)
	MOVD    R25, 152(R1)
	MOVD    R26, 160(R1)
	MOVD    R27, 168(R1)
	MOVD    R28, 176(R1)
	MOVD    R29, 184(R1)
	MOVD    g, 192(R1) // R30
	MOVD    R31, 200(R1)
	FMOVD   F14, 208(R1)
	FMOVD   F15, 216(R1)
	FMOVD   F16, 224(R1)
	FMOVD   F17, 232(R1)
	FMOVD   F18, 240(R1)
	FMOVD   F19, 248(R1)
	FMOVD   F20, 256(R1)
	FMOVD   F21, 264(R1)
	FMOVD   F22, 272(R1)
	FMOVD   F23, 280(R1)
	FMOVD   F24, 288(R1)
	FMOVD   F25, 296(R1)
	FMOVD   F26, 304(R1)
	FMOVD   F27, 312(R1)
	FMOVD   F28, 320(R1)
	FMOVD   F29, 328(R1)
	FMOVD   F30, 336(R1)
	FMOVD   F31, 344(R1)
	// Save V regs
	// STXVD2X and LXVD2X used since
	// we aren't sure of alignment.
	// Endianness doesn't matter
	// if we are just loading and
	// storing values.
	MOVD	$352, R7 // V20
	STXVD2X VS52, (R7)(R1)
	ADD	$16, R7 // V21 368
	STXVD2X VS53, (R7)(R1)
	ADD	$16, R7 // V22 384
	STXVD2X VS54, (R7)(R1)
	ADD	$16, R7 // V23 400
	STXVD2X VS55, (R7)(R1)
	ADD	$16, R7 // V24 416
	STXVD2X	VS56, (R7)(R1)
	ADD	$16, R7 // V25 432
	STXVD2X	VS57, (R7)(R1)
	ADD	$16, R7 // V26 448
	STXVD2X VS58, (R7)(R1)
	ADD	$16, R7 // V27 464
	STXVD2X VS59, (R7)(R1)
	ADD	$16, R7 // V28 480
	STXVD2X VS60, (R7)(R1)
	ADD	$16, R7 // V29 496
	STXVD2X VS61, (R7)(R1)
	ADD	$16, R7 // V30 512
	STXVD2X VS62, (R7)(R1)
	ADD	$16, R7 // V31 528
	STXVD2X VS63, (R7)(R1)

	// initialize essential registers (just in case)
	BL	runtime·reginit(SB)

	// this might be called in external code context,
	// where g is not set.
	MOVBZ	runtime·iscgo(SB), R6
	CMP	R6, $0
	BEQ	2(PC)
	BL	runtime·load_g(SB)

	MOVW	R3, FIXED_FRAME+0(R1)
	MOVD	R4, FIXED_FRAME+8(R1)
	MOVD	R5, FIXED_FRAME+16(R1)
	MOVD	$runtime·sigtrampgo(SB), R12
	MOVD	R12, CTR
	BL	(CTR)
	MOVD	24(R1), R2 // Should this be here? Where is it saved?
	// Starts at 64; FIXED_FRAME is 32
	MOVD    64(R1), R14
	MOVD    72(R1), R15
	MOVD    80(R1), R16
	MOVD    88(R1), R17
	MOVD    96(R1), R18
	MOVD    104(R1), R19
	MOVD    112(R1), R20
	MOVD    120(R1), R21
	MOVD    128(R1), R22
	MOVD    136(R1), R23
	MOVD    144(R1), R24
	MOVD    152(R1), R25
	MOVD    160(R1), R26
	MOVD    168(R1), R27
	MOVD    176(R1), R28
	MOVD    184(R1), R29
	MOVD    192(R1), g // R30
	MOVD    200(R1), R31
	FMOVD   208(R1), F14
	FMOVD   216(R1), F15
	FMOVD   224(R1), F16
	FMOVD   232(R1), F17
	FMOVD   240(R1), F18
	FMOVD   248(R1), F19
	FMOVD   256(R1), F20
	FMOVD   264(R1), F21
	FMOVD   272(R1), F22
	FMOVD   280(R1), F23
	FMOVD   288(R1), F24
	FMOVD   292(R1), F25
	FMOVD   300(R1), F26
	FMOVD   308(R1), F27
	FMOVD   316(R1), F28
	FMOVD   328(R1), F29
	FMOVD   336(R1), F30
	FMOVD   344(R1), F31
	MOVD	$352, R7
	LXVD2X	(R7)(R1), VS52
	ADD	$16, R7 // 368 V21
	LXVD2X	(R7)(R1), VS53
	ADD	$16, R7 // 384 V22
	LXVD2X	(R7)(R1), VS54
	ADD	$16, R7 // 400 V23
	LXVD2X	(R7)(R1), VS55
	ADD	$16, R7 // 416 V24
	LXVD2X	(R7)(R1), VS56
	ADD	$16, R7 // 432 V25
	LXVD2X	(R7)(R1), VS57
	ADD	$16, R7 // 448 V26
	LXVD2X	(R7)(R1), VS58
	ADD	$16, R8 // 464 V27
	LXVD2X	(R7)(R1), VS59
	ADD	$16, R7 // 480 V28
	LXVD2X	(R7)(R1), VS60
	ADD	$16, R7 // 496 V29
	LXVD2X	(R7)(R1), VS61
	ADD	$16, R7 // 512 V30
	LXVD2X	(R7)(R1), VS62
	ADD	$16, R7 // 528 V31
	LXVD2X	(R7)(R1), VS63
	ADD	$544, R1
	MOVD	8(R1), R0
	MOVFL	R0, $0xff
	MOVD	16(R1), R0
	MOVD	R0, LR

	RET

#ifdef GOARCH_ppc64le
// ppc64le doesn't need function descriptors
TEXT runtime·cgoSigtramp(SB),NOSPLIT|NOFRAME,$0
	// The stack unwinder, presumably written in C, may not be able to
	// handle Go frame correctly. So, this function is NOFRAME, and we
	// save/restore LR manually.
	MOVD	LR, R10

	// We're coming from C code, initialize essential registers.
	CALL	runtime·reginit(SB)

	// If no traceback function, do usual sigtramp.
	MOVD	runtime·cgoTraceback(SB), R6
	CMP	$0, R6
	BEQ	sigtramp

	// If no traceback support function, which means that
	// runtime/cgo was not linked in, do usual sigtramp.
	MOVD	_cgo_callers(SB), R6
	CMP	$0, R6
	BEQ	sigtramp

	// Set up g register.
	CALL	runtime·load_g(SB)

	// Figure out if we are currently in a cgo call.
	// If not, just do usual sigtramp.
	// compared to ARM64 and others.
	CMP	$0, g
	BEQ	sigtrampnog // g == nil
	MOVD	g_m(g), R6
	CMP	$0, R6
	BEQ	sigtramp    // g.m == nil
	MOVW	m_ncgo(R6), R7
	CMPW	$0, R7
	BEQ	sigtramp    // g.m.ncgo = 0
	MOVD	m_curg(R6), R7
	CMP	$0, R7
	BEQ	sigtramp    // g.m.curg == nil
	MOVD	g_syscallsp(R7), R7
	CMP	$0, R7
	BEQ	sigtramp    // g.m.curg.syscallsp == 0
	MOVD	m_cgoCallers(R6), R7 // R7 is the fifth arg in C calling convention.
	CMP	$0, R7
	BEQ	sigtramp    // g.m.cgoCallers == nil
	MOVW	m_cgoCallersUse(R6), R8
	CMPW	$0, R8
	BNE	sigtramp    // g.m.cgoCallersUse != 0

	// Jump to a function in runtime/cgo.
	// That function, written in C, will call the user's traceback
	// function with proper unwind info, and will then call back here.
	// The first three arguments, and the fifth, are already in registers.
	// Set the two remaining arguments now.
	MOVD	runtime·cgoTraceback(SB), R6
	MOVD	$runtime·sigtramp(SB), R8
	MOVD	_cgo_callers(SB), R12
	MOVD	R12, CTR
	MOVD	R10, LR // restore LR
	JMP	(CTR)

sigtramp:
	MOVD	R10, LR // restore LR
	JMP	runtime·sigtramp(SB)

sigtrampnog:
	// Signal arrived on a non-Go thread. If this is SIGPROF, get a
	// stack trace.
	CMPW	R3, $27 // 27 == SIGPROF
	BNE	sigtramp

	// Lock sigprofCallersUse (cas from 0 to 1).
	MOVW	$1, R7
	MOVD	$runtime·sigprofCallersUse(SB), R8
	SYNC
	LWAR    (R8), R6
	CMPW    $0, R6
	BNE     sigtramp
	STWCCC  R7, (R8)
	BNE     -4(PC)
	ISYNC

	// Jump to the traceback function in runtime/cgo.
	// It will call back to sigprofNonGo, which will ignore the
	// arguments passed in registers.
	// First three arguments to traceback function are in registers already.
	MOVD	runtime·cgoTraceback(SB), R6
	MOVD	$runtime·sigprofCallers(SB), R7
	MOVD	$runtime·sigprofNonGoWrapper<>(SB), R8
	MOVD	_cgo_callers(SB), R12
	MOVD	R12, CTR
	MOVD	R10, LR // restore LR
	JMP	(CTR)
#else
// function descriptor for the real sigtramp
TEXT runtime·cgoSigtramp(SB),NOSPLIT|NOFRAME,$0
	DWORD	$cgoSigtramp<>(SB)
	DWORD	$0
	DWORD	$0
TEXT cgoSigtramp<>(SB),NOSPLIT,$0
	JMP	sigtramp<>(SB)
#endif

// func mmap(addr uintptr, n uintptr, prot int, flags int, fd int, off int64) (ret uintptr, err error)
TEXT runtime·mmap(SB),NOSPLIT|NOFRAME,$0
	MOVD	addr+0(FP), R3
	MOVD	n+8(FP), R4
	MOVW	prot+16(FP), R5
	MOVW	flags+20(FP), R6
	MOVW	fd+24(FP), R7
	MOVW	off+28(FP), R8

	SYSCALL	$SYS_mmap
	BVC	ok
	MOVD	$0, p+32(FP)
	MOVD	R3, err+40(FP)
	RET
ok:
	MOVD	R3, p+32(FP)
	MOVD	$0, err+40(FP)
	RET

// func munmap(addr uintptr, n uintptr) (err error)
TEXT runtime·munmap(SB),NOSPLIT|NOFRAME,$0
	MOVD	addr+0(FP), R3
	MOVD	n+8(FP), R4
	SYSCALL	$SYS_munmap
	BVC	2(PC)
	MOVD	R0, 0xf0(R0)
	RET

// func madvise(addr unsafe.Pointer, n uintptr, flags int32) int32
TEXT runtime·madvise(SB),NOSPLIT|NOFRAME,$0
	MOVD	addr+0(FP), R3
	MOVD	n+8(FP), R4
	MOVW	flags+16(FP), R5
	SYSCALL	$SYS_madvise
	BVC	2(PC)
	MOVW    $-1, R3
	MOVW	R3, ret+24(FP)
	RET

// func sysctl(mib *uint32, miblen uint32, out *byte, size *uintptr, dst *byte, ndst uintptr) int32
// arm64 MOVD	miblen+8(FP), R1
TEXT runtime·sysctl(SB),NOSPLIT,$0
	MOVD	mib+0(FP), R3		// arg 1 - name
	MOVW	miblen+8(FP), R4	// arg 2 - namelen
	MOVD	out+16(FP), R5		// arg 3 - oldp
	MOVD	size+24(FP), R6		// arg 4 - oldlenp
	MOVD	dst+32(FP), R7		// arg 5 - newp
	MOVD	ndst+40(FP), R8		// arg 6 - newlen
	SYSCALL	$SYS___sysctl
	BVC	2(PC)
	MOVW	$-1, R3
	MOVW	R3, ret+48(FP)
	RET

// func sigaltstack(new, old *stackt)
TEXT runtime·sigaltstack(SB),NOSPLIT|NOFRAME,$0
	MOVD	new+0(FP), R3
	MOVD	old+8(FP), R4
	SYSCALL	$SYS_sigaltstack
	BVC	2(PC)
	MOVD	R0, 0xf0(R0)  // crash
	RET

// func osyield()
TEXT runtime·osyield(SB),NOSPLIT|NOFRAME,$0
	SYSCALL	$SYS_sched_yield
	RET

// func sigprocmask(how int32, new, old *sigset)
TEXT runtime·sigprocmask(SB),NOSPLIT|NOFRAME,$0-24
	MOVW	how+0(FP), R3
	MOVD	new+8(FP), R4
	MOVD	old+16(FP), R5
	SYSCALL	$SYS_sigprocmask
	BVC	2(PC)
	MOVD	R0, 0xf0(R0)	// crash
	RET

// func cpuset_getaffinity(level int, which int, id int64, size int, mask *byte) int32
TEXT runtime·cpuset_getaffinity(SB),NOSPLIT|NOFRAME,$0-44
	MOVD	level+0(FP), R3
	MOVD	which+8(FP), R4
	MOVD	id+16(FP), R5
	MOVD	size+24(FP), R6
	MOVD	mask+32(FP), R7
	SYSCALL	$SYS_cpuset_getaffinity
	BVC	2(PC)
	MOVW	$-1, R3
	MOVW	R3, ret+40(FP)
	RET

// func kqueue() int32
TEXT runtime·kqueue(SB),NOSPLIT|NOFRAME,$0
	SYSCALL	$SYS_kqueue
	BVC	2(PC)
	MOVW	$-1, R3
	MOVW	R3, ret+0(FP)
	RET

// func kevent(kq int, ch unsafe.Pointer, nch int, ev unsafe.Pointer, nev int, ts *Timespec) (n int, err error)
TEXT runtime·kevent(SB),NOSPLIT,$0
	MOVW	kq+0(FP), R3	// arg 1 - kq
	MOVD	ch+8(FP), R4	// arg 2 - changelist
	MOVW	nch+16(FP), R5	// arg 3 - nchanges
	MOVD	ev+24(FP), R6	// arg 4 - eventlist
	MOVW	nev+32(FP), R7	// arg 5 - nevents
	MOVD	ts+40(FP), R8	// arg 6 - timeout
	SYSCALL	$SYS_kevent
	BVC	2(PC)
	NEG	R3, R3
ok:
	MOVW	R3, ret+48(FP)
	RET

// func fcntl(fd, cmd, arg int32) (int32, int32)
TEXT runtime·fcntl(SB),NOSPLIT,$0
	MOVW	fd+0(FP), R3
	MOVW	cmd+4(FP), R4
	MOVW	arg+8(FP), R5
	SYSCALL	$SYS_fcntl
	BVC	noerr
	MOVW	$-1, R4
	MOVW	R4, ret+16(FP)
	MOVW	R3, errno+20(FP)
	RET
noerr:
	MOVW	R3, ret+16(FP)
	MOVW	$0, errno+20(FP)
	RET

// func runtime·setNonblock(fd int32)
TEXT runtime·setNonblock(SB),NOSPLIT|NOFRAME,$0-4
	MOVW    fd+0(FP), R3 // fd
	MOVD    $3, R4  // F_GETFL
	MOVD    $0, R5
	SYSCALL $SYS_fcntl
	OR      $0x800, R3, R5 // O_NONBLOCK
	MOVW    fd+0(FP), R3 // fd
	MOVD    $4, R4  // F_SETFL
	SYSCALL $SYS_fcntl
	RET

// func issetugid() int32
TEXT runtime·issetugid(SB),NOSPLIT|NOFRAME,$0
	SYSCALL $SYS_issetugid
	MOVW	R3, ret+0(FP)
	RET
