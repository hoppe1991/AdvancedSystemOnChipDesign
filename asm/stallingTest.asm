.data
29005572
.text
addi	$t2,	$zero,	7	# Initialize reg 10 with 7
addi	$t3,	$zero,	2	# Initialize reg 11 with 2
addi	$t4,	$zero,	9	# Initialize reg 12 with 9
addi	$t5,	$zero,	77	# Initialize reg 13 with 77
subu	$sp,	$sp,	4	# Decrease stack pointer by 4 byte
sw	$t2,	0($sp)		# Write value 7 at current stack pointer
lw	$s2,	0($sp)		# Load value of current sp into reg 18      		#32
nop
lw	$s2,	0($sp)		# Load value of current sp into reg 18      		#32
#nop				# No hazard with this nop

add	$s4,	$s2,	$t5	# Add reg 18 and reg 13, store result in reg 20   	#40

add	$s4,	$s4,	$zero	# Add reg 18 and reg 13, store result in reg 20   	#44

or	$t6,	$t3,	$s2	# Reg 14 = reg 11 OR reg 18							#48
and	$t7,	$s2,	$t4	# Reg 15 = reg 18 AND reg 12

#TESTING FORWARD FUNCTION
addi	$t2,	$zero,	2	# Initialize reg 10 with 7
addi	$t3,	$zero,	3	# Initialize reg 11 with 2
addi	$t4,	$zero,	4	# Initialize reg 12 with 9
addi	$t5,	$zero,	5	# Initialize reg 11 with 2
addi	$t6,	$zero,	6	# Initialize reg 12 with 9

sub $s2, $t1, $t3
add $s4, $s2, $t5
or $s6, $t3, $s2
and $s7, $s6, $s2
sw $t8, 10($s2)


add $t4, $t3, $t2



