.section .text
.global _start

_start:
    addi x1, x0, 5
    addi x2, x0, 3
    add x3, x1, x2
    sub x4, x1, x2
    and x5, x1, x2
    or x6, x1, x2
    xor x14, x1, x2
    sll x15, x1, x2
    srl x16, x1, x2
    sw x3, 40(x0)
    lw x7, 40(x0)

    # Branch 1: falls through to 111 because x1 != x2
    beq x1, x2, .+8
    addi x10, x0, 111

    # Branch 2: Taken! x3 == x7, jumps over 999
    beq x3, x7, .+8
    addi x10, x0, 999
    addi x10, x0, 222

    # Jal Jump: Taken! jumps over 555
    jal x6, .+8
    addi x11, x0, 555
    addi x12, x0, 77

    flw  f1, 0(x0)
    flw  f2, 4(x0)
    fadd.s f3, f1, f2
    fsub.s f4, f2, f1
    fsw f3, 8(x0)
    lw x13, 8(x0)
    feq.s x9, f3, f3
    feq.s x8, f3, f4
    fmul.s f5, f1, f2
    fdiv.s f6, f2, f1


