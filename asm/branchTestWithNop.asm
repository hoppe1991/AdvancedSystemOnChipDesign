.data
29005572
.text
	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, 1	# b = 1
	nop
	nop
	nop
	beq $t2, $t1, L1	# if ( a == b ) then goto L1
	#nop
	addi $t3, $zero, 4	# c = 4
	addi $s3, $zero, 0	# f = 0
	addi $t5, $zero, 8	# e = 8
L1:	nop
	sub $t7, $zero, 7
	addi $t2, $zero, 5	# b = 5

	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, 0	# b = 0
	
	beq $t1, $t2, L2	# if ( a == b ) then goto L2
	addi $t1, $zero, 4	# a = 4
	addi $t2, $zero, 5	# b = 5
	sub $t6, $t6, $zero	# y = y - 0
	sub $t7, $t7, $zero	# x = x - 0
L2:	addi $t1, $zero, 1	# a = 1
	addi $t2, $zero, 1	# b = 1
