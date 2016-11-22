# load and store
      .data
val:  .word  0xA1B2C3D4      # size of "array" 
      .text
      la   $t1, val
      lw   $t2, 0($t1)
      sw   $t2  4($t1) 
      lb   $t3, 0($t1)
      sb   $t2, 8($t1)
      lb   $t4, 1($t1)
      #sb   $t2, 9($t1)
      lb   $t5, 2($t1)
     # sb   $t2, 10($t1)
      lb   $t6, 3($t1)
     # sb   $t2, 11($t1)
lable:      lh   $t7, 0($t1)
      sh   $t2, 12($t1)
      lh   $s0, 2($t1)
      lbu  $s1, 0($t1)
      lbu  $s2, 1($t1)
      lbu  $s3, 2($t1)
      lbu  $s4, 3($t1)
      lhu  $s5, 0($t1)
      lhu  $s6, 2($t1)
      b lable
      move	$3,$2