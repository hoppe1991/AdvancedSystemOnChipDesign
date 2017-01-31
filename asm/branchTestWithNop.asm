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
	and $t5, $t3, $t4	# c = 4
	or $t5, $t3, $t4	# f = 0
	addi $t5, $zero, 8	# e = 8
L1:	nop
	sub $t7, $zero, 7
	addi $t2, $zero, 5	# b = 5

	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, 0	# b = 0
	
	beq $t1, $t2, L2	# if ( a == b ) then goto L2
	nop
	addi $t1, $zero, 4	# a = 4
	addi $t2, $zero, 5	# b = 5
	sub $t6, $t6, $zero	# y = y - 0
	sub $t7, $t7, $zero	# x = x - 0
L2:	addi $t1, $zero, 1	# a = 1
	addi $t2, $zero, 1	# b = 1


nop
nop
nop


######################### TESTING BNE

	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, 1	# b = 1
	nop
	nop
	nop
	bne $t2, $t1, L1BNE	# if ( a == b ) then goto L1BNE
	#nop
	and $t5, $t3, $t4	# c = 4
	or $t5, $t3, $t4	# f = 0
	addi $t5, $zero, 8	# e = 8
L1BNE:	nop
	sub $t7, $zero, 7
	addi $t2, $zero, 5	# b = 5

	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, 0	# b = 0
	
	bne $t1, $t2, L2BNE	# if ( a == b ) then goto L2BNE
	nop
	addi $t1, $zero, 4	# a = 4
	addi $t2, $zero, 5	# b = 5
	sub $t6, $t6, $zero	# y = y - 0
	sub $t7, $t7, $zero	# x = x - 0
L2BNE:	addi $t1, $zero, 1	# a = 1
	addi $t2, $zero, 1	# b = 1




######################### TESTING BLEZ

	addi $t1, $zero, -1	# a = 0
	addi $t2, $zero, 1	# b = 1
	nop
	nop
	nop
	BLEZ $t1, L1BLEZ	# if ( a == b ) then goto L1BLEZ
	#nop
	and $t5, $t3, $t4	# c = 4
	or $t5, $t3, $t4	# f = 0
	addi $t5, $zero, 8	# e = 8
L1BLEZ:	nop
	sub $t7, $zero, 7
	addi $t2, $zero, 5	# b = 5

	addi $t1, $zero, 1	# a = 0
	addi $t2, $zero, 0	# b = 0
	
	BLEZ $t1, L2BLEZ	# if ( a == b ) then goto L2BLEZ
	nop
	addi $t1, $zero, 4	# a = 4
	addi $t2, $zero, 5	# b = 5
	sub $t6, $t6, $zero	# y = y - 0
	sub $t7, $t7, $zero	# x = x - 0
L2BLEZ:	addi $t1, $zero, 1	# a = 1
	addi $t2, $zero, 1	# b = 1
	
	
	nop
	nop
	nop
	nop
	nop
	
	
######################### TESTING BLTZ

	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, -1	# b = -1
	nop
	nop
	nop
	BLTZ $t2, L1BLTZ	# if ( a == b ) then goto L1BLTZ
	#nop
	and $t5, $t3, $t4	# c = 4
	or $t5, $t3, $t4	# f = 0
	addi $t5, $zero, 8	# e = 8
L1BLTZ:	nop
	sub $t7, $zero, 7
	addi $t2, $zero, 5	# b = 5

	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, 0	# b = 0
	
	BLTZ $t2, L2BLTZ	# if ( a == b ) then goto L2BLTZ
	nop
	addi $t1, $zero, 4	# a = 4
	addi $t2, $zero, 5	# b = 5
	sub $t6, $t6, $zero	# y = y - 0
	sub $t7, $t7, $zero	# x = x - 0
L2BLTZ:	addi $t1, $zero, 1	# a = 1
	addi $t2, $zero, 1	# b = 1




	nop
	nop
	nop
	nop
	nop
	

######################### TESTING BGTZ

	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, -1	# b = -1
	nop
	nop
	nop
	BGTZ $t2, L1BGTZ	# if ( a == b ) then goto L1BGTZ
	#nop
	and $t5, $t3, $t4	# c = 4
	or $t5, $t3, $t4	# f = 0
	addi $t5, $zero, 8	# e = 8
L1BGTZ:	nop
	sub $t7, $zero, 7
	addi $t2, $zero, 5	# b = 5

	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, 1	# b = 0
	
	BGTZ $t2, L2BGTZ	# if ( a == b ) then goto L2BGTZ
	nop
	addi $t1, $zero, 4	# a = 4
	addi $t2, $zero, 5	# b = 5
	sub $t6, $t6, $zero	# y = y - 0
	sub $t7, $t7, $zero	# x = x - 0
L2BGTZ:	addi $t1, $zero, 1	# a = 1
	addi $t2, $zero, 1	# b = 1
	
	
	
	
nop
nop
nop
nop
nop

####################### TESTING J

	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, 1	# b = 1
	nop
	nop
	nop
	J L1J	# Jump
	#nop
	and $t5, $t3, $t4	# c = 4
	nop
	or $t5, $t3, $t4	# f = 0
	addi $t5, $zero, 8	# e = 8
L1J:	nop
	sub $t7, $zero, 7
	addi $t2, $zero, 5	# b = 5

	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, 0	# b = 0
	
	J L2J	#
	nop
	addi $t1, $zero, 4	# a = 4
	addi $t2, $zero, 5	# b = 5
	sub $t6, $t6, $zero	# y = y - 0
	sub $t7, $t7, $zero	# x = x - 0
L2J:	addi $t1, $zero, 5	# a = 1
	addi $t2, $zero, 6	# b = 1


nop
nop
nop






####################### TESTING JAL

	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, 1	# b = 1
	nop
	nop
	nop
	JAL L1JAL	# Jump
	#nop
	and $t5, $t3, $t4	# c = 4
	nop
	or $t5, $t3, $t4	# f = 0
	addi $t5, $zero, 8	# e = 8
L1JAL:	nop
	sub $t7, $zero, 7
	addi $t2, $zero, 5	# b = 5

	addi $t1, $zero, 0	# a = 0
	addi $t2, $zero, 0	# b = 0
	
	JAL L2JAL	#
	nop
	addi $t1, $zero, 4	# a = 4
	addi $t2, $zero, 5	# b = 5
	sub $t6, $t6, $zero	# y = y - 0
	sub $t7, $t7, $zero	# x = x - 0
L2JAL:	addi $t1, $zero, 5	# a = 1
	addi $t2, $zero, 6	# b = 1


nop
nop
nop


