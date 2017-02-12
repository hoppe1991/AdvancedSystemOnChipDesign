.data
val:   .word   4

.text
       nop
       addi $t1, $zero, 0	# sum = 0
       addi $t2, $zero, 0	# i = 0
       addi $t3, $zero, 20	# $t3 = 20
       
for:   beq $t2, $t3, done	# if i == 20
       add $t1, $t1, $t2	# sum = sum + i
       addi $t2, $t2, 1		# increment i
       j for
done: