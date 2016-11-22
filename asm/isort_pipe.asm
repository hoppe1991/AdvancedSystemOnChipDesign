# Insertionsort

            .data                                       # data segment

len:        .word 10                                    # Länge der Liste
val:        .word 20, 30, 10, 40, 50, 60, 30, 25, 10, 5 # Liste

            .text                                       # Code segment
            .globl main                                 # Globaler Name
            
main:      nop
           jal isort
           nop
           nop
           nop
end:       j end 
           nop
           nop
           nop           

isort:                                                  # isort()
            # reg usage
            # $2 -> i                           $3 -> j
            # $4 -> k                           $5 -> n[...]
            # $6 -> address of val[...]         $7 -> value of val[l-1]
            # $8 -> base address of val[...]    $9 -> 4 (size of int)
                      
for_init:   addi $2, $0, 1
            lui  $1, 0x1001     # lw   $7, len     addr = 0x10010000
            nop
            nop
            nop
            lw   $7, 0($1)
            addi $1, $0, 1      # array length (10) in $1
            nop
            nop 
            nop
            sub  $7, $7, $1
            lui  $1, 0x1001     # la   $8, val  pseudo ins. for load address
            nop
            nop
            nop
            ori  $8, $1, 4      # reg[8] = addr(val[0]); 
            addi $9, $0, 4

for_loop:   slt  $1, $7, $2     # bgt  $2, $7, end_for
            nop
            nop
            nop
            bne  $1, $0, end_for #21
            nop
            nop 
            nop
            addi $1, $0, 1      # sub  $3, $2, 1
            nop
            nop
            nop
            sub  $3, $2, $1
            mul  $6, $2, $9     # addr(val[i]) = addr(val[0])+i*(size(int))
            nop
            nop
            nop
            add  $6, $8, $6
            nop
            nop
            nop
            lw   $4, 0($6)
            nop
            nop
 
while_init: slti $1, $3, 0     # blt  $3, 0,  end_while
            nop
            nop
            nop
            bne  $1, $0, end_while
            nop
            nop
            nop
            mul  $6, $3, $9    # addr(val[i]) = addr(val[0])+i*(size(int))
            nop
            nop
            nop
            add  $6, $8, $6
            nop
            nop
            nop
            lw   $5, 0($6)
            nop
            nop
            nop
            slt  $1, $4, $5    # ble  $5, $4, end_while
            nop
            nop
            nop
            beq  $1, $0, end_while
            nop
            nop
            nop
            sw   $5, 4($6)
            addi $1, $0, 1     # sub  $3, $3, 1
            nop
            nop
            sub  $3, $3, $1
            j            while_init
            nop
            nop
            nop

end_while:  mul  $6, $3, $9    # addr(val[i]) = addr(val[0])+i*(size(int))
            nop
            nop
            nop
            add  $6, $8, $6
            nop
            nop
            nop
            sw   $4, 4($6)
            addi $2, $2, 1
            j            for_loop
            nop
            nop
            nop
end_for:    j            return
            nop
            nop
            nop
return:     jr   $ra
            nop
            nop
            nop
