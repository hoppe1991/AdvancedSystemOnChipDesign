.data
val:   .word   4

.text
       nop
       lw     $a0  val        # load value to $a0
       nop
fac:   bne    $a0, $zero, gen # if $a0<>0, goto generic case
       ori    $v0, $zero, 1   # else set result $v0 = 1
       jr     $ra             # return
gen:
       addi   $sp, $sp, -8    # make room for 2 registers on stack
       sw     $ra, 4($sp)     # save return address register $ra
       sw     $a0, 0($sp)     # save argument register $a0=n
   
       addi    $a0, $a0, -1   # $a0 = n-1      
       jal fac                # $v0 = fac(n-1)
     
       lw      $a0, 0($sp)    # restore $a0=n
       lw      $ra, 4($sp)    # restore $ra
       addi    $sp, $sp, 8    # multipop stack
      
       mul     $v0, $v0, $a0  # $v0 = fac(n-1) x n
       jr      $ra            # return
