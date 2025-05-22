// push constant 0
@0
D=A
@SP
AM=M+1
A=A-1
M=D
// pop local 0
@LCL
A=M
D=A
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// for SUM_END argument 0
(SUM_END_LOOP_START)
@ARG
D=M
@0
A=D+A
D=M
@SUM_END_END
D;JEQ
// push argument 0
@ARG
A=M
D=M
@SP
AM=M+1
A=A-1
M=D
// push local 0
@LCL
A=M
D=M
@SP
AM=M+1
A=A-1
M=D
// add
@SP
AM=M-1
D=M
A=A-1
M=D+M
// pop local 0
@LCL
A=M
D=A
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// for-end SUM_END
@SUM_END
M=M-1
@SUM_END_LOOP_START
0;JMP
(SUM_END_END)
// push local 0
@LCL
A=M
D=M
@SP
AM=M+1
A=A-1
M=D
