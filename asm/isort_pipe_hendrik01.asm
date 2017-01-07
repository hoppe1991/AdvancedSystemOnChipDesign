# Insertionsort

            .data                                       # data segment

len:        .word 10                                    # Länge der Liste
val:        .word 20, 30, 10, 40, 50, 60, 30, 25, 10, 5 # Liste

            .text                                       # Code segment
            .globl main                                 # Globaler Name
            
main:      	
			nop
			nop
			nop
			jal isort

end:      		
			nop
			nop
			nop
			j end            

isort:                                                  # isort()
            # reg usage
            # $2 -> i                           $3 -> j
            # $4 -> k                           $5 -> n[...]
            # $6 -> address of val[...]         $7 -> value of val[l-1]
            # $8 -> base address of val[...]    $9 -> 4 (size of int)
                      
for_init:   

			nop
			nop
			nop



			addi $2, $0, 1
			nop
			nop
			nop
			lw   $7, len
			nop
			nop
			nop

			sub  $7, $7, 1
			nop
			nop
			nop
            la   $8, val       # pseudo instr.: load address: reg[8] = addr(val[0]); 
	#		addi $8, $zero, Addr(val)
			nop
			nop
			nop
            addi $9, $0, 4
			nop
			nop
			nop

for_loop:   

			nop
			nop
			nop

		#	bgt  $2, $7, end_for
			
			slt $t0, $7, $2
			nop
			nop
			nop


			bne	$t0, $zero, end_for			
			nop
			nop
			nop
			sub  $3, $2, 1     
			nop
			nop
			nop
			mul  $6, $2, $9    # addr(val[i]) = addr(val[0])+i*(size(int))
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
			nop

			
 
while_init: 
			nop
			nop
			nop
	#		blt  $3, 0,  end_while
			slt $t0, $3, $zero
			nop
			nop
			nop
			bne $t0, $zero, end_while
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
           # ble  $5, $4, end_while
			slt $t0, $4, $5

			nop
			nop
			nop


beq $t0, $zero, end_while
			
			
			nop
			nop
			nop
            sw   $5, 4($6)
			nop
			nop
			nop
            sub  $3, $3, 1
			nop
			nop
			nop
            j            while_init
			nop
			nop
			nop

end_while:  

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
            sw   $4, 4($6)
			nop
			nop
			nop
            addi $2, $2, 1
			nop
			nop
			nop
            j            for_loop
			nop
			nop
			nop
end_for:  
			nop
			nop
			nop

j            return
			nop
			nop
			nop

return:     			
			nop
			nop
			nop
jr   $ra
			nop
			nop
			nop
