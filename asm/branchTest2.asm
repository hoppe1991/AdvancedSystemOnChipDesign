.data
29005572
.text
	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, 1	# b = 1
	addi $t3, $zero, 5	# c = 5
	addi $t4, $zero, 10	# d = 10
	addi $t5, $zero, 4	# e = 4
	addi $t6, $zero, 1	# f = 1
	nop
	nop
	nop
	nop
	nop
	beq $t2, $t1, L1	# if ( a == b ) then goto L1
	mul $t4, $t4, $t4	# d = d * d
	sub $t3, $t3, $zero	# c = c - 0
	and $t5, $t5, $t5	# e = e and e
L1:	add $t6, $t6, $t6	# f = f + f
