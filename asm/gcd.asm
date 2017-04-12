# Subject       :	Advanced System-on-Chip Design
# Author:	:	Meyer zum Felde, Püttjer, Hoppe
# Date:		:	30/3/2016
# Version:	:	1
# ============================================================================
# $a0 --> a
# $a1 --> b
# ============================================================================
            .data                                       # data segment

len:        .word 2                                    # LÃ¤nge der Liste
val:        .word 3528, 3780 				# Liste

            .text                                       # Code segment
            .globl main                                 # Globaler Name
# ============================================================================
main:	
 
	lui  $1, 0x1001     # lw   $7, len     addr = 0x10010000 
        lw   $a0, 0($1)
        lw   $a0, 4($1)	   	# a = 3528
        lw   $a1, 8($1)		# b = 3780

	jal gcd 		# call function
	
	sw   $v0, 12($1)	# Store result into data memory.
	
	jal end 		# call function
# ============================================================================
gcd:
if:	bne $a0, $zero, else 	# if ( a != 0 ) branch to else
	add $v0, $zero, $a1	# return b
	jr $ra			# return b
else:
while:	beq $a1, $0, done	# while (b != 0) {
				# if ( a > b )
	slt $t1, $a1, $a0	# if ( b < a ) then t1 = 1 else t1 = 0
	beq $t1, $zero, else2	# if (t1 == 0) then PC <- Addr(else2)
	sub $a0, $a0, $a1 	# a -= b
	j while			# PC <- Addr(while)
else2:	sub $a1, $a1, $a0 	# b -= a
	j while			# PC <- Addr(while)
done:				# }
	add $v0, $zero, $a0	# return a
	jr $ra			# return a
end:	j end 