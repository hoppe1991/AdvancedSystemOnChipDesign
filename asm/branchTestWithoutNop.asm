.data
29005572
.text
	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, 1	# b = 1
	beq $t1, $t2, L1	# if ( a == b ) then goto L1
	addi $t3, $zero, 4	# c = 4
	addi $t4, $zero, 6	# d = 4
L1:	addi $t2, $zero, 5	# b = 5
	
	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, 0	# b = 0
	beq $t1, $t2, L2	# if ( a == b ) then goto L2
	addi $t1, $zero, 4	# a = 4
	addi $t2, $zero, 5	# b = 5	
L2:	addi $t1, $zero, 1	# a = 1
	addi $t2, $zero, 1	# b = 1