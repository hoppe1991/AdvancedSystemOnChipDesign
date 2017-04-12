# Compute first twelve Fibonacci numbers and put in array
      .data
fibs: .word   0 : 12        # "array" of 12 words to contain fib values
size: .word  12             # size of "array" 
      .text
      
      
      la   $t0, fibs        # load address of array
      # TODO
      # lui $t0, Upper(Addr(fibs))
      # ori $rs, $rs, Lower(Addr(Label))
      
      
      la   $t5, size        # load address of size variable
      # TODO Rewrite la 
      
      lw   $t5, 0($t5)      # load array size
      nop
      nop
      nop
      
      addi $t2, $t2, 1      # 1 is first and second Fib. number
      nop
      nop
      nop
      
      sw   $t2, 0($t0)      # F[0] = 1
      nop
      nop
      nop
      
      sw   $t2, 4($t0)      # F[1] = F[0] = 1
      nop
      nop
      nop
      
      addi $t1, $t5, -2     # Counter for loop, will execute (size-2) times
      nop
      nop
      nop
      
      addi $t3, $t3, 0
      nop
      nop
      nop
      
loop: lw   $t3, 0($t0)      # Get value from array F[n] 
      nop
      nop
      nop
      
      lw   $t4, 4($t0)      # Get value from array F[n+1]
      nop
      nop
      nop
      
      add  $t2, $t3, $t4    # $t2 = F[n] + F[n+1]
      nop
      nop
      nop
      
      sw   $t2, 8($t0)      # Store F[n+2] = F[n] + F[n+1] in array
      nop
      nop
      nop
      
      addi $t0, $t0, 4      # increment address of Fib. number source
      nop
      nop
      nop
      
      addi $t1, $t1, -1     # decrement loop counter
      nop
      nop
      nop
      
      bgt  $t1, $0, loop    # repeat if not finished yet.
      # TODO Rewrite
      
      la   $a0, fibs        # first argument for print (array)
      # TODO Rewrite
      
      add  $a1, $zero, $t5  # second argument for print (size)
      nop
      nop
      nop