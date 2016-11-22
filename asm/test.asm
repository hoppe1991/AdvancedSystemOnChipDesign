# Assembly                    Description            Address  Machine
main:   addi $11, $11, 1
        addi $12, $12, 2
        bne  $11, $12, snd
third:  la   $11, around 
        jr   $11
func:   lui  $8, 100
        addi $2, $0, 5        # initialize $2 = 5    0        20020005
        addi $3, $0, 12       # initialize $3 = 12   4        2003000c
        addi $7, $3, -9       # initialize $7 = 3    8        2067fff7
        mul  $9, $3, $7
        add  $9, $9, $2
        lui  $8, 0xffff
        xor  $9, $9, $8
        slti $10, $9, 30
        xori $10, $10, 0x00aa
        ori  $10, $10, 0xff00
        andi $10, $10 0x5555
        sll  $10, $10, 1
        lui  $10, 0xffff 
        sra  $10, $10, 1
        srl  $10, $10, 1
        or   $4, $7, $2       # $4 = (3 OR 5) = 7    c        00e22025
        and  $5, $3, $4       # $5 = (12 AND 7) = 4  10       00642824
        add  $5, $5, $4       # $5 = 4 + 7 = 11      14       00a42820
        beq  $5, $7, end      # shouldn't be taken   18       10a7000a
        slt  $4, $3, $4       # $4 = 12 < 7 = 0      1c       0064202a
        jr $ra
        beq  $4, $0, around   # should be taken      20       10800001
        addi $5, $0, 0        # shouldn't happen     24       20050000
around: slt  $4, $7, $2       # $4 = 3 < 5 = 1       28       00e2202a
        addi $7, $7, 913      # $7 = 1 + 11 = 12     2c       00853820
        addi $3, $3, 12
        sub  $7, $7, $2       # $7 = 12 - 5 = 7      30       00e23822
        sw   $7,  4($3)       # [14] = 7             34       ac670044
        addi $8, $0, 8
        lw  $2, 16($0)        # $2 = [14] = 7        38       8c020050
        j   end               # should be taken      3c       08000011
        addi $2, $0, 1        # shouldn't happen     40       20020001
snd:    j third        
end:    sw   $2, 84($0)       # write mem[84] = 7    44       ac020054
        jal func
        nop
