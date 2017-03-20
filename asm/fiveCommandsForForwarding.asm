.data 
268500992
.text 
addi $t1, $zero, 12		#	Register 9 	Wert 12
addi $t3, $zero, 4		#	Register 11	Wert 4
addi $t5, $zero, 3		#	Register 13	Wert 3
addi $t8, $zero, 111	#	Reigster 24 Wert 111
sub $s2, $t1, $t3		#	Register 18	Wert 8
add $s4, $s2, $t5		#	Register 20	Wert 11
or $s6, $t3, $s2		#	Register 22	Wert 12
and $s7, $s6, $s2		#	Register 23	Wert 8
add $s2, $zero, $gp		#	Register 18	Wert globalpointer... 
sw $t8, 8($s2)
nop
nop
nop