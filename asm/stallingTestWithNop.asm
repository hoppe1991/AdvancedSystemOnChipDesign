.data
29005572
.text
addi	$t2,	$zero,	7	# Initialize reg 10 with 7
addi	$t3,	$zero,	2	# Initialize reg 11 with 2
addi	$t4,	$zero,	9	# Initialize reg 12 with 9
addi	$t5,	$zero,	77	# Initialize reg 13 with 77
subu	$sp,	$sp,	4	# Decrease stack pointer by 4 byte
sw	$t2,	0($sp)		# Write value 7 at current stack pointer
lw	$s2,	0($sp)		# Load value of current sp into reg 18
nop				# No hazard with this nop
add	$s4,	$s2,	$t5	# Add reg 18 and reg 13, store result in reg 20
or	$t6,	$t3,	$s2	# Reg 14 = reg 11 OR reg 18
and	$t7,	$s2,	$t4	# Reg 15 = reg 18 AND reg 12
