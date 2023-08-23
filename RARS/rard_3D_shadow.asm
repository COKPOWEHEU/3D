.eqv DISP_W 256
.eqv DISP_H 256
.eqv DISP_MID_X 128
.eqv DISP_MID_Y 128

.data 0x10000000
DISP_BASE:
.space 0x040000 #256x256x4
DISP_BASE_END:
DISP_BG:
.space 0x080000
DISP_ZBUF:
.space 0x080000
DISP_ZBUF_END:
VERTEX_CALC:
.space 12000
VERTEX_END:
NORMAL_CALC:
.space 12000
NORMAL_END:
MAT:
.space 36
MAT_END:
ANGLE:
.align 2
.half 0x8000
.half 0
.half 0
.align 3


.text
  li sp, 0x7FFFEFFC
  
ROT_LOOP:
  call MAT_IDEN
  la s0, ANGLE
  lh a0, 0(s0)
  addi a0, a0, 250
  sh a0, 0(s0)
  srli a0, a0, 8
  call MAT_ROT_X
  
  lh a0, 2(s0)
  addi a0, a0, 313
  sh a0, 2(s0)
  srli a0, a0, 8
  call MAT_ROT_Y
  
  lh a0, 4(s0)
  addi a0, a0, 486
  sh a0, 4(s0)
  srli a0, a0, 8
  call MAT_ROT_Z
  
  call CALC_POINTS
  call CALC_NORMALS

  call DRAW_MODEL
  call SWAP_BUFFERS
j ROT_LOOP
  
  li a7, 10
  ecall
LOOP:
  j LOOP

.macro swap %a %b
  xor %a, %a, %b
  xor %b, %a, %b
  xor %a, %a, %b
.end_macro
.macro push %x
  addi sp, sp, -4
  sw %x, 0(sp)
.end_macro
.macro pop %x
  lw %x, 0(sp)
  addi sp, sp, 4
.end_macro
.macro push4 %a, %b, %c, %d
  addi sp, sp, -16
  sw %a, 12(sp)
  sw %b, 8(sp)
  sw %c, 4(sp)
  sw %d, 0(sp)
.end_macro
.macro pop4 %a, %b, %c, %d
  lw %d, 0(sp)
  lw %c, 4(sp)
  lw %b, 8(sp)
  lw %a, 12(sp)
  addi sp, sp, 16
.end_macro

#a0 = x, a1 = y1, a2 = z1, a3 = y2, a4 = z2, a5 = col
VLINE:
  beq a1, a3, VLINE_END
  push4 ra, a1, a2, a3
  push a4
  push4 s0, s1, s2, s3
  blt a1, a3, VLINE_NSWAP
    swap a1, a3
    swap a2, a4
VLINE_NSWAP:
  sub s3, a3, a1 # s3 = dy
  mv s2, zero    # s2 = err
  sub s0, a4, a2 # s0 = dz
  li s1, 1       # s1 = ddz
  bgtz s0, VLINE_POS
    neg s0, s0
    neg s1, s1
VLINE_POS:
  #mv a5, a2
  call PIXZ
  add s2, s2, s0
VLINE_TEST_Z:
  blt s2, s3, VLINE_Z
    sub s2, s2, s3
    add a2, a2, s1
    j VLINE_TEST_Z
VLINE_Z:
  addi a1, a1, 1
  blt a1, a3, VLINE_POS
  
  pop4 s0, s1, s2, s3
  pop a4
  pop4 ra, a1, a2, a3
VLINE_END:
ret

#a0 = A, a1 = B, a2 = C, a3 = N, a5=color
.data
TRI_BASE:
.eqv AX, 0
.eqv AY, 4
.eqv AZ, 8
.eqv BX, 12
.eqv BY, 16
.eqv BZ, 20
.eqv CX, 24
.eqv CY, 28
.eqv CZ, 32
.eqv X1E, 36
.eqv Y1E, 40
.eqv Z1E, 44
.eqv X2E, 48
.eqv Y2E, 52
.eqv Z2E, 56
.eqv DY1, 60
.eqv DZ1, 64
.eqv DY2, 68
.eqv DZ2, 72
.eqv ERRY1, 80
.eqv ERRY2, 84
.eqv ERRZ1, 88
.eqv ERRZ2, 92
.eqv DDY1, 96
.eqv DDY2, 100
.eqv DDZ1, 104
.eqv DDZ2, 108
.space 200

.text
.globl TRIANGLE
TRIANGLE:
  push4 ra, s0, s1, s2
  push4 s3, s4, s5, s11
  push a5
  
  la s0, NORMAL_CALC
  li t0, 12
  mul t0, t0, a3
  add t0, t0, s0 #t0 = normal
  lw t1, 0(t0)
  lw t2, 4(t0)
  lw t3, 8(t0)
  
  li t0, 127 # light.x
  mul t1, t1, t0
  li t0, 0 # light.y
  mul t2, t2, t0
  li t0, 0 # light.z
  mul t3, t3, t0
  add t0, t1, t2
  add t0, t0, t3
  li t1, 127
  div t0, t0, t1 # t0 = brightness
  srli t0, t0, 1
  addi t0, t0, 63
  blt t0, t1, BRIGHT_CEIL
    li t0, 127
BRIGHT_CEIL:
  andi t1, a5, 0xFF
  srli t2, a5, 8
  andi t2, t2, 0xFF
  srli t3, a5, 16
  andi t3, t3, 0xFF
  mul t1, t1, t0
  mul t2, t2, t0,
  mul t3, t3, t0
  li t0, 127
  div t1, t1, t0
  div t2, t2, t0
  div t3, t3, t0
  slli a5, t3, 16
  slli t2, t2, 8
  or a5, a5, t2
  or a5, a5, t1
  
  
  la s0, VERTEX_CALC
  li t0, 12
  mul s1, a1, t0
  add s1, s1, s0 # s1 = B
  mul s2, a2, t0
  add s2, s2, s0 # s2 = C
  mul t0, a0, t0
  add s0, s0, t0 # s0 = A
  
  #copy points to regs
  la s11, TRI_BASE
  lw t0, 0(s0)
  lw t1, 4(s0)
  lw s3, 8(s0)
  lw t2, 0(s1)
  lw t3, 4(s1)
  lw s4, 8(s1)
  lw t4, 0(s2)
  lw t5, 4(s2)
  lw s5, 8(s2)
  
  blt t0, t2, TRI_AB
    swap t0, t2
    swap t1, t3
    swap s3, s4
TRI_AB:
  blt t0, t4, TRI_AC
    swap t0, t4
    swap t1, t5
    swap s3, s5
TRI_AC:
  blt t2, t4, TRI_BC
    swap t2, t4
    swap t3, t5
    swap s4, s5
TRI_BC:
  sw t0, AX(s11)
  sw t1, AY(s11)
  sw s3, AZ(s11)
  sw t2, BX(s11)
  sw t3, BY(s11)
  sw s4, BZ(s11)
  sw t4, CX(s11)
  sw t5, CY(s11)
  sw s5, CZ(s11)
###################
  sw t2, X1E(s11) # x1e = b.x
  sw t3, Y1E(s11) # y2e = b.y
  sw s4, Z1E(s11) # z1e = b.z
  sw t4, X2E(s11) # x2e = c.x
  sw t5, Y2E(s11) # y2e = c.y
  sw s5, Z2E(s11) # z2e = c.z
  
  sub s0, t2, t0 # s0 = dx1
  sub s1, t4, t0 # s1 = dx2
  mv a0, t0      # a0 = x
  mv a1, t1      # a1 = y1
  mv a2, s3      # a2 = z1
  mv a3, t1      # a3 = y2
  mv a4, s3      # a4 = z2
  #li a5, 0x00FFFFFF # a5 = color
  
  sw zero, ERRY1(s11)
  sw zero, ERRZ1(s11)
  sw zero, ERRY2(s11)
  sw zero, ERRZ2(s11)
  
  sub t3, t3, t1 # t3 = dy1
  li t0, 1
  bgtz t3, TRI_DY1_POS
    neg t3, t3
    neg t0, t0
TRI_DY1_POS:
  sw t3, DY1(s11)
  sw t0, DDY1(s11)
  
  sub s4, s4, a2 # s4 = dz1
  li t0, 1
  bgtz s4, TRI_DZ1_POS
    neg s4, s4
    neg t0, t0
TRI_DZ1_POS:
  sw s4, DZ1(s11)
  sw t0, DDZ1(s11)
    
  sub t5, t5, t1 # t5 = dy2
  li t0, 1
  bgtz t5, TRI_DY2_POS
    neg t5, t5
    neg t0, t0
TRI_DY2_POS:
  sw t5, DY2(s11)
  sw t0, DDY2(s11)
  
  
  
  sub s5, s5, a2 #s5 = dz2
  li t0, 1
  bgtz s5, TRI_DZ2_POS
    neg s5, s5
    neg t0, t0
TRI_DZ2_POS:
  sw s5, DZ2(s11)
  sw t0, DDZ2(s11)
  
  
TRI_LOOP:
  #if (x == b.x)
  lw t0, X1E(s11)
  bne a0, t0, TRI_NOT_B
    lw t0, CX(s11)
    lw t1, BX(s11)
    sub s0, t0, t1 # dx1 = c.x - b.x
      beqz s0, TRI_END
    lw t0, CY(s11)
    lw a1, BY(s11) # y1 = b.y
    sub t0, t0, a1
    li t1, 1
    bgtz t0, TRI_B_DY_POS
      neg t0, t0
      neg t1, t1
TRI_B_DY_POS:
    sw t0, DY1(s11) # dy1 = c.y - b.y
    sw t1, DDY1(s11)
    sw zero, ERRY1(s11)
    
    lw t0, CZ(s11)
    lw a2, BZ(s11) # z1 = b.z
    sub t0, t0, a2
    li t1, 1
    bgtz t0, TRI_B_DZ_POS
      neg t0, t0
      neg t1, t1
TRI_B_DZ_POS:
    sw t0, DZ1(s11) # dz1 = c.z - b.z
    sw t1, DDZ1(s11)
    sw zero, ERRZ1(s11)
TRI_NOT_B:

  call VLINE
  
  beqz s0, TRI_DX1_ZERO # if dx1 == 0 -> skip
  lw t0, ERRY1(s11)
  lw t1, DY1(s11)
  add t0, t0, t1 # err_y1 += dy1
  lw t1, DDY1(s11)
TRI_TEST_ERR_Y1:
  blt t0, s0, TRI_ERR_Y1 #if err_y1 < dx1 -> do nothing
    sub t0, t0, s0 # err_y1 -= dx1
    add a1, a1, t1 # y1 += ddy1
    j TRI_TEST_ERR_Y1
TRI_ERR_Y1:
  sw t0, ERRY1(s11)
  
  lw t0, ERRZ1(s11)
  lw t1, DZ1(s11)
  add t0, t0, t1
  lw t1, DDZ1(s11)
TRI_TEST_ERR_Z1:
  blt t0, s0, TRI_ERR_Z1
    sub t0, t0, s0
    add a2, a2, t1
    j TRI_TEST_ERR_Z1
TRI_ERR_Z1:
  sw t0, ERRZ1(s11)
TRI_DX1_ZERO:

  beqz s1, TRI_DX2_ZERO # if dx2 == 0 -> skip
  lw t0, ERRY2(s11)
  lw t1, DY2(s11)
  add t0, t0, t1 # err_y2 += dy2
  lw t1, DDY2(s11)
TRI_TEST_ERR_Y2:
  blt t0, s1, TRI_ERR_Y2 # if err_y2 < dx2 -> do nothing
    sub t0, t0, s1 # err_y2 -= dx2
    add a3, a3, t1 # y2 += ddy2
    j TRI_TEST_ERR_Y2
TRI_ERR_Y2:
  sw t0, ERRY2(s11)
  
  lw t0, ERRZ2(s11)
  lw t1, DZ2(s11)
  add t0, t0, t1
  lw t1, DDZ2(s11)
TRI_TEST_ERR_Z2:
  blt t0, s1, TRI_ERR_Z2
    sub t0, t0, s1
    add a4, a4, t1
    j TRI_TEST_ERR_Z2
TRI_ERR_Z2:
  sw t0, ERRZ2(s11)
TRI_DX2_ZERO:
  
  addi a0, a0, 1        # x++
  lw t0, X2E(s11)
  blt a0, t0, TRI_LOOP # if x < x2e -> continue loop
  

  
TRI_END:
  pop a5
  pop4 s3, s4, s5, s11
  pop4 ra, s0, s1, s2
ret

#a0 = x1, a1 = y1, a2 = x2, a3 = y2, a4 = color
LINE:
  push4 ra, s0, s1, s2
  push s3
  beq a0, a2, LINE_END
  blt a0, a2, LINE_NSWAP
    swap a0, a2
    swap a1, a3
LINE_NSWAP:
  sub s0, a2, a0 # s0 = dx
  sub s1, a3, a1 # s1 = dy
  li s2, 1	 # s2 = ddy
  bgez s1, LINE_POS_DY
    li s2, -1
    neg s1, s1
LINE_POS_DY:
  sub s3, zero, s0 # s3 = err
LINE_LOOP:
  call PIX
  add s3, s3, s1 # err += dx
LINE_TEST_HORIZ:
  bltz s3, LINE_HORIZ
    sub s3, s3, s0 # err -= dx
    add a1, a1, s2 # y += ddy
    beq a1, a2, LINE_HORIZ
    j LINE_TEST_HORIZ
LINE_HORIZ:
  addi a0, a0, 1
  bne a0, a2, LINE_LOOP
  
LINE_END:
  pop s3
  pop4 ra, s0, s1, s2
ret

# a0 = x, a1 = y, a4 = color
# a0, a1, a4 - Saves by this func!
# t0, t1 - temporary
PIX:
  bltz a0, PIX_END
  bltz a1, PIX_END
  addi t0, a0, -DISP_W
  bgez t0, PIX_END
  addi t0, a1, -DISP_H
  bgtz t0, PIX_END
  li t0, DISP_W
  mul t0, t0, a1
  add t0, t0, a0
  slli t0, t0, 2
  la t1, DISP_BG
  #la t1, DISP_BASE
  add t0, t0, t1
  sw a4, 0(t0)
PIX_END:
ret

# a0 = x, a1 = y, a2 = z, a5 = color
PIXZ:
  bltz a0, PIXZ_END
  bltz a1, PIXZ_END
  addi t0, a0, -DISP_W
  bgez t0, PIXZ_END
  addi t0, a1, -DISP_H
  bgtz t0, PIXZ_END
  li t0, DISP_W
  mul t0, t0, a1
  add t0, t0, a0
  slli t0, t0, 2
  la t2, DISP_ZBUF
  la t1, DISP_BG
  #la t1, DISP_BASE
  add t1, t1, t0
  add t2, t2, t0
  lw t0, 0(t2)
  bgt a2, t0, PIXZ_END
  sw a5, 0(t1)
  sw a2, 0(t2)
PIXZ_END:
ret

SWAP_BUFFERS:
  la t0, DISP_ZBUF
  la t1, DISP_ZBUF_END
  li t2, 0x7FFFFFFF
SWAPBUF_ZBUF:
  sw t2, 0(t0)
  addi t0, t0, 4
    bne t0, t1, SWAPBUF_ZBUF
#ret
  la t0, DISP_BASE
  la t1, DISP_BG
  la t2, DISP_BASE_END
SWAPBUF_COLOR:
  lw t3, 0(t1)
  sw t3, 0(t0)
  sw zero, 0(t1)
  addi t0, t0, 4
  addi t1, t1, 4
    bne t0, t2, SWAPBUF_COLOR
ret


CALC_POINTS:
  push ra
  push s0
  
  la a0, VERTEX_CALC
  la a1, VERTEX_SRC
  la s0, VERTEX_SRC_END
CALCP_LOOP:
  call VEC_MUL
  addi a0, a0, 12
  addi a1, a1, 3
  blt a1, s0, CALCP_LOOP
  
  pop s0
  pop ra
ret

CALC_NORMALS:
  push ra
  push s0
  
  la a0, NORMAL_CALC
  la a1, NORMAL_SRC
  la s0, NORMAL_SRC_END
NORMALS_LOOP:
  call VEC_MUL
  addi a0, a0, 12
  addi a1, a1, 3
  blt a1, s0, NORMALS_LOOP
  
  pop s0
  pop ra
ret

.data
SIN_TABLE:
.byte 0,3,6,9,12,16,19,22,25,28,31,34,37,40,43,46,49,51,54,57,60,63,65,68,71,73,76,78,81,83,85,88,90,92,94,96,98,100,102,104,106,107,109,111,112,113,115,116,117,118,120,121,122,122,123,124,125,125,126,126,126,127,127,127,127,127,127,127,126,126,126,125,125,124,123,122,122,121,120,118,117,116,115,113,112,111,109,107,106,104,102,100,98,96,94,92,90,88,85,83,81,78,76,73,71,68,65,63,60,57,54,51,49,46,43,40,37,34,31,28,25,22,19,16,12,9,6,3,0,-3,-6,-9,-12,-16,-19,-22,-25,-28,-31,-34,-37,-40,-43,-46,-49,-51,-54,-57,-60,-63,-65,-68,-71,-73,-76,-78,-81,-83,-85,-88,-90,-92,-94,-96,-98,-100,-102,-104,-106,-107,-109,-111,-112,-113,-115,-116,-117,-118,-120,-121,-122,-122,-123,-124,-125,-125,-126,-126,-126,-127,-127,-127,-127,-127,-127,-127,-126,-126,-126,-125,-125,-124,-123,-122,-122,-121,-120,-118,-117,-116,-115,-113,-112,-111,-109,-107,-106,-104,-102,-100,-98,-96,-94,-92,-90,-88,-85,-83,-81,-78,-76,-73,-71,-68,-65,-63,-60,-57,-54,-51,-49,-46,-43,-40,-37,-34,-31,-28,-25,-22,-19,-16,-12,-9,-6,-3
SIN_END:


#matrix operations
.data
MAT_BUF:
.space 36
MAT_BUF_END:
.text
MAT_IDEN:
  la t0, MAT
  li t1, 32767
  
  sw t1, 0(t0)
  sw zero, 4(t0)
  sw zero, 8(t0)
  
  sw zero, 12(t0)
  sw t1, 16(t0)
  sw zero, 20(t0)
  
  sw zero, 24(t0)
  sw zero, 28(t0)
  sw t1, 32(t0)
ret
MAT_COPY:
  la t0, MAT
  la t1, MAT_END
  la t2, MAT_BUF
MAT_COPY_LOOP:
  lw t3, 0(t0)
  sw t3, 0(t2)
  addi t0, t0, 4
  addi t2, t2, 4
  bne t0, t1, MAT_COPY_LOOP
ret
# a0 = angle
MAT_ROT_X:
  push ra
  call MAT_COPY
  
  andi a0, a0, 0xFF
  la t0, SIN_TABLE
  addi t1, a0, 64 # cos(alp) = sin(alp + pi/4)
  andi t1, t1, 0xFF
  add t1, t1, t0
  lb t1, 0(t1)  # t1 = cos(alp)
  add t0, t0, a0
  lb t0, 0(t0)  # t0 = sin(alp)
  li t2, 127
  
  la t3, MAT
  la t4, MAT_BUF
  
  #mat[1,0] = (buf[1,0]*cos - buf[2,0]*sin)/127
  lw t5, 4(t4)
  mul t5, t5, t1
  lw t6, 8(t4)
  mul t6, t6, t0
  sub t5, t5, t6
  div t5, t5, t2
  sw t5, 4(t3)
  #mat[2,0] = (buf[1,0]*sin + buf[2,0]*cos)/127
  lw t5, 4(t4)
  mul t5, t5, t0
  lw t6, 8(t4)
  mul t6, t6, t1
  add t5, t5, t6
  div t5, t5, t2
  sw t5, 8(t3)
  #mat[1,1] = (buf[1,1]*cos - buf[2,1]*sin)/127
  lw t5, 16(t4)
  mul t5, t5, t1
  lw t6, 20(t4)
  mul t6, t6, t0
  sub t5, t5, t6
  div t5, t5, t2
  sw t5, 16(t3)
  #mat[2,1] = (buf[1,1]*sin + buf[2,1]*cos)/127
  lw t5, 16(t4)
  mul t5, t5, t0
  lw t6, 20(t4)
  mul t6, t6, t1
  add t5, t5, t6
  div t5, t5, t2
  sw t5, 20(t3)
  #mat[1,2] = (buf[1,2]*cos - buf[2,2]*sin)/127
  lw t5, 28(t4)
  mul t5, t5, t1
  lw t6, 32(t4)
  mul t6, t6, t0
  sub t5, t5, t6
  div t5, t5, t2
  sw t5, 28(t3)
  #mat[2,2] = (buf[1,2]*sin + buf[2,2]*cos)/127
  lw t5, 28(t4)
  mul t5, t5, t0
  lw t6, 32(t4)
  mul t6, t6, t1
  add t5, t5, t6
  div t5, t5, t2
  sw t5, 32(t3)
  
  pop ra
ret
# a0 = angle
MAT_ROT_Y:
  push ra
  call MAT_COPY
  
  andi a0, a0, 0xFF
  la t0, SIN_TABLE
  addi t1, a0, 64 # cos(alp) = sin(alp + pi/4)
  andi t1, t1, 0xFF
  add t1, t1, t0
  lb t1, 0(t1)  # t1 = cos(alp)
  add t0, t0, a0
  lb t0, 0(t0)  # t0 = sin(alp)
  li t2, 127
  
  la t3, MAT
  la t4, MAT_BUF
  
  #mat[0,0] = (buf[0,0]*cos - buf[2,0]*sin)/127
  lw t5, 0(t4)
  mul t5, t5, t1
  lw t6, 8(t4)
  mul t6, t6, t0
  sub t5, t5, t6
  div t5, t5, t2
  sw t5, 0(t3)
  #mat[2,0] = (buf[0,0]*sin + buf[2,0]*cos)/127
  lw t5, 0(t4)
  mul t5, t5, t0
  lw t6, 8(t4)
  mul t6, t6, t1
  add t5, t5, t6
  div t5, t5, t2
  sw t5, 8(t3)
  #mat[0,1] = (buf[0,1]*cos - buf[2,1]*sin)/127
  lw t5, 12(t4)
  mul t5, t5, t1
  lw t6, 20(t4)
  mul t6, t6, t0
  sub t5, t5, t6
  div t5, t5, t2
  sw t5, 12(t3)
  #mat[2,1] = (buf[0,1]*sin + buf[2,1]*cos)/127
  lw t5, 12(t4)
  mul t5, t5, t0
  lw t6, 20(t4)
  mul t6, t6, t1
  add t5, t5, t6
  div t5, t5, t2
  sw t5, 20(t3)
  #mat[0,2] = (buf[0,2]*cos - buf[2,2]*sin)/127
  lw t5, 24(t4)
  mul t5, t5, t1
  lw t6, 32(t4)
  mul t6, t6, t0
  sub t5, t5, t6
  div t5, t5, t2
  sw t5, 24(t3)
  #mat[2,2] = (buf[0,2]*sin + buf[2,2]*cos)/127
  lw t5, 24(t4)
  mul t5, t5, t0
  lw t6, 32(t4)
  mul t6, t6, t1
  add t5, t5, t6
  div t5, t5, t2
  sw t5, 32(t3)
  
  pop ra
ret
# a0 = angle
MAT_ROT_Z:
  push ra
  call MAT_COPY
  
  andi a0, a0, 0xFF
  la t0, SIN_TABLE
  addi t1, a0, 64 # cos(alp) = sin(alp + pi/4)
  andi t1, t1, 0xFF
  add t1, t1, t0
  lb t1, 0(t1)  # t1 = cos(alp)
  add t0, t0, a0
  lb t0, 0(t0)  # t0 = sin(alp)
  li t2, 127
  
  la t3, MAT
  la t4, MAT_BUF
  
  #mat[0,0] = (buf[0,0]*cos - buf[1,0]*sin)/127
  lw t5, 0(t4)
  mul t5, t5, t1
  lw t6, 4(t4)
  mul t6, t6, t0
  sub t5, t5, t6
  div t5, t5, t2
  sw t5, 0(t3)
  #mat[1,0] = (buf[0,0]*sin + buf[1,0]*cos)/127
  lw t5, 0(t4)
  mul t5, t5, t0
  lw t6, 4(t4)
  mul t6, t6, t1
  add t5, t5, t6
  div t5, t5, t2
  sw t5, 4(t3)
  #mat[0,1] = (buf[0,1]*cos - buf[1,1]*sin)/127
  lw t5, 12(t4)
  mul t5, t5, t1
  lw t6, 16(t4)
  mul t6, t6, t0
  sub t5, t5, t6
  div t5, t5, t2
  sw t5, 12(t3)
  #mat[1,1] = (buf[0,1]*sin + buf[1,1]*cos)/127
  lw t5, 12(t4)
  mul t5, t5, t0
  lw t6, 16(t4)
  mul t6, t6, t1
  add t5, t5, t6
  div t5, t5, t2
  sw t5, 16(t3)
  #mat[0,2] = (buf[0,2]*cos - buf[1,2]*sin)/127
  lw t5, 24(t4)
  mul t5, t5, t1
  lw t6, 28(t4)
  mul t6, t6, t0
  sub t5, t5, t6
  div t5, t5, t2
  sw t5, 24(t3)
  #mat[1,2] = (buf[0,2]*sin + buf[1,2]*cos)/127
  lw t5, 24(t4)
  mul t5, t5, t0
  lw t6, 28(t4)
  mul t6, t6, t1
  add t5, t5, t6
  div t5, t5, t2
  sw t5, 28(t3)
  
  pop ra
ret

#a0 = dst_addr, a1 = src_addr
VEC_MUL:
  la t0, MAT
  li t1, 32767
  lb t2, 0(a1)
  lb t3, 1(a1)
  lb t4, 2(a1)
  # x = ( x*mat[0,0] + y*mat[1,0] + z*mat[2,0] )/32767
  lw t5, 0(t0)
  mul t6, t2, t5
  lw t5, 4(t0)
  mul t5, t3, t5
  add t6, t6, t5
  lw t5, 8(t0)
  mul t5, t4, t5
  add t6, t6, t5
  div t6, t6, t1
  addi t6, t6, DISP_MID_X
  sw t6, 0(a0)
  # y = ( x*mat[0,1] + y*mat[1,1] + z*mat[2,1] )/32767
  lw t5, 12(t0)
  mul t6, t2, t5
  lw t5, 16(t0)
  mul t5, t3, t5
  add t6, t6, t5
  lw t5, 20(t0)
  mul t5, t4, t5
  add t6, t6, t5
  div t6, t6, t1
  addi t6, t6, DISP_MID_Y
  sw t6, 4(a0)
  # z = ( x*mat[0,2] + y*mat[1,2] + z*mat[2,2] )/32767
  lw t5, 24(t0)
  mul t6, t2, t5
  lw t5, 28(t0)
  mul t5, t3, t5
  add t6, t6, t5
  lw t5, 32(t0)
  mul t5, t4, t5
  add t6, t6, t5
  div t6, t6, t1
  sw t6, 8(a0)
ret

.include "shadow.inc"
