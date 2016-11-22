     .data
len: .word 20
val: .word 20, 30, 10, 40, 50, 60, 30, 25, 10, 5, 
           17, 33, 65,  5, 90,  4, 27, 45, 55, 55
           
               
     .text

     #addi $2, $0, 1
     lw   $5, len
     #sub  $7, $7, 1
     la   $4, val       # pseudo instr.: load address: reg[8] = addr(val[0]); 
   #  addi $9, $0, 4
qsort: # performs quicksort on array at $a0, with length $a1
     addi $sp,$sp,-12    # allocate stack space
     sw   $ra,12($sp)  # save return address
     slti $t0,$a1,2      # if(len <= 1)
     bne  $t0,$0,$END    # jump to end (already sorted)
     addi $t0,$0,2
     bne  $t0,$a1,$Chuck # if(len==2) compare the 2
     lw   $t1,0($a0)     # load array[0]
     lw   $t2,4($a0)     # load array[1]
     slt  $t0,$t2,$t1    # if array[1] < array[0]
     beq  $t0,$0,$END
     sw   $t1,4($a0)     # swap array[0] and array[1]
     sw   $t2,0($a0)
     j    $END     # now we're done
$Chuck: # this is where the actual quicksort happens
     srl  $t0,$a1,1      # piv = len / 2
     sll  $t0,$t0,2      # align to word size
     add  $t0,$a0,$t0    # mem addr. of pivot
     lw   $t1,0($t0)     # $t1 = mem[piv]
     addi $t2,$a1,-1     # $t2 = len - 1;
     sll  $t2,$t2,2      # align to word size
     add  $t2,$a0,$t2    # mem addr. of end
     lw   $t3,0($t2)     # t3 = mem[end]
     sw   $t3,0($t0)     # swap pivot and end value
     sw   $t1,0($t2)
     # pivot value is in $t1
     add  $t5,$t2,$0     # j = piv - 1
     add  $t3,$a0,$0   # i = 0
     slt  $t7,$t3,$t5  # while(i < j)
     beq  $t7,$0,$Kick
$Norris: # while(array[i] < array[piv]) i++;
     lw   $t4,0($t3)
     slt  $t7,$t4,$t1    # if(array[i] < array[piv])
     beq  $t7,$0,$Round
     addi $t3,$t3,4      # move to next word
     j    $Norris
$Round: # while(array[j] > array[piv]) j--;
     lw   $t6,0($t5)
     slt  $t7,$t1,$t6    # if(array[j] > array[piv])
     beq  $t7,$0,$House
     addi $t5,$t5,-4     # move to next word
     j    $Round
$House: # if (i < j)
     slt  $t7,$t3,$t5
     beq  $t7,$0,$Kick
     sw   $t6,0($t3)   # swap(array[i],array[j])
     sw   $t4,0($t5)
     j    $Norris        # loop through again
$Kick: # now reset pivot and recurse
     lw   $t7,0($t3)   # $t7 = array[i]
     sw   $t1,0($t3)     # array[i] = array[piv]
     sw   $t7,0($t2)     # array[piv] = array[i]
     addi $t8,$t3,4      # address of [i+1] (for 2nd call)
     sw   $t8,4($sp)   # save to stack for later
     sub  $t9,$t3,$a0  # mem offset of i from $a0
     srl  $t9,$t9,2      # value of i
     sub  $t0,$a1,$t9    # len - i
     addi $t0,$t0,-1     # len - i - 1
     sw   $t0,8($sp)   # save to stack for later
     addi $a1,$t9,-1     # len = i-1 = j
     jal  qsort          # qsort(array,len)
     lw   $t8,4($sp)     # reload ptr to 2nd partition
     lw   $t9,8($sp)     # reload length of 2nd partition
     add  $a0,$t8,$0   # save to $a0
     add  $a1,$t9,$0   # save to $a1
     jal  qsort    # qsort(array+i+1,len-i-1)
$END:
     lw   $ra,12($sp)  # reload return address
     addi $sp,$sp,12   # deallocate stack space
     jr   $ra            # return from function