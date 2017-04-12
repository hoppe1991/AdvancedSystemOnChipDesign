.data
val:   .word   4

.text
       nop
       lw     $a0  val        # load value to $a0
       nop
       nop
       nop
       
fac:   bne    $a0, $zero, gen # if $a0<>0, goto generic case
       nop
       nop
       nop
       
       ori    $v0, $zero, 1   # else set result $v0 = 1
       nop
       nop
       nop
       
       jr     $ra             # return
       nop
       nop
       nop
gen:
       addi   $sp, $sp, -8    # make room for 2 registers on stack
       nop
       nop
       nop
       
       sw     $ra, 4($sp)     # save return address register $ra
       nop
       nop
       nop
       
       sw     $a0, 0($sp)     # save argument register $a0=n
       nop
       nop
       nop
   
       addi    $a0, $a0, -1   # $a0 = n-1 
       nop
       nop
       nop
            
       jal fac                # $v0 = fac(n-1)
       nop
       nop
       nop
     
       lw      $a0, 0($sp)    # restore $a0=n       
       nop
       nop
       nop
       
       lw      $ra, 4($sp)    # restore $ra
       nop
       nop
       nop
       
       addi    $sp, $sp, 8    # multipop stack
       nop
       nop
       nop
      
       mul     $v0, $v0, $a0  # $v0 = fac(n-1) x n
       nop
       nop
       nop
       
       jr      $ra            # return
       nop
       nop
       nop