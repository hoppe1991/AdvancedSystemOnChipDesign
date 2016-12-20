.data
268500992
.text
addi $t1, $zero, 12
addi $t3, $zero, 4
addi $t5, $zero, 3
addi $t8, $zero, 111
sub $s2, $t1, $t3
add $s4, $s2, $t5
or $s6, $t3, $s2
and $s7, $s6, $s2
add $s2, $zero, $gp
sw $t8, 8($s2)
