# Insertionsort

            .data                                       # data segment

len:        .word 10                                    # Länge der Liste
val:        .word 20, 30, 10, 40, 50, 60, 30, 25, 10, 5 # Liste

            .text                                       # Code segment
            .globl main                                 # Globaler Name
            
main:      jal isort
end:       j end            

isort:                                                  # isort()
            # reg usage
            # $2 -> i                           $3 -> j
            # $4 -> k                           $5 -> n[...]
            # $6 -> address of val[...]         $7 -> value of val[l-1]
            # $8 -> base address of val[...]    $9 -> 4 (size of int)
                      
for_init:   addi $2, $0, 1
            lw   $7, len
            sub  $7, $7, 1
            la   $8, val       # pseudo instr.: load address: reg[8] = addr(val[0]); 
            addi $9, $0, 4

for_loop:   bgt  $2, $7, end_for
            sub  $3, $2, 1
            mul  $6, $2, $9    # addr(val[i]) = addr(val[0])+i*(size(int))
            add  $6, $8, $6
            lw   $4, 0($6)
 
while_init: blt  $3, 0,  end_while
            mul  $6, $3, $9    # addr(val[i]) = addr(val[0])+i*(size(int))
            add  $6, $8, $6
            lw   $5, 0($6)
            ble  $5, $4, end_while
            sw   $5, 4($6)
            sub  $3, $3, 1
            j            while_init

end_while:  mul  $6, $3, $9    # addr(val[i]) = addr(val[0])+i*(size(int))
            add  $6, $8, $6
            sw   $4, 4($6)
            addi $2, $2, 1
            j            for_loop
end_for:    j            return
return:     jr   $ra