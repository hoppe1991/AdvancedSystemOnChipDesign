.data
29005572
.text


j main
main:

addi	$t2,	$zero,	7	# Initialize reg 10 with 7
addi    $t6,    $zero,  5	# Initialize reg 14 with 5
bne     $t2,    $t6, 	L1	# if 7 != 5, skip if block
addi     $t6,    $zero,  0	# Initialize reg 14 with 0
L1: sub $t6, $t6, 1		# Decrement reg 14 by 1

addi     $t6,    $zero,  0	# Initialize reg 14 with 0
addi     $t6,    $zero,  0	# Initialize reg 14 with 0
addi     $t6,    $zero,  0	# Initialize reg 14 with 0
addi     $t6,    $zero,  0	# Initialize reg 14 with 0
addi     $t6,    $zero,  0	# Initialize reg 14 with 0
addi     $t6,    $zero,  0	# Initialize reg 14 with 0
j L2
L2:






addi	$t3,	$zero,	2	# Initialize reg 11 with 2
addi	$t4,	$zero,	9	# Initialize reg 12 with 9
addi	$t5,	$zero,	77	# Initialize reg 13 with 77
subu	$sp,	$sp,	4	# Decrease stack pointer by 4 byte
sw	$t2,	0($sp)		# Write value 7 at current stack pointer
lw	$s2,	0($sp)		# Load value of current sp into reg 18
#nop				# No hazard with this nop
add	$s4,	$s2,	$t5	# Add reg 18 and reg 13, store result in reg 20
or	$t6,	$t3,	$s2	# Reg 14 = reg 11 OR reg 18
and	$t7,	$s2,	$t4	# Reg 15 = reg 18 AND reg 12
