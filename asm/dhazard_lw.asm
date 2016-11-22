     .data 
len: .word 10                                    # Länge der Liste
val: .word 20, 30, 10, 40, 50, 60, 30, 25, 10, 5 # Liste
     .text
     nop
     addi $9, $9, 0x5555
     lui  $1, 0x1001     # lw   $7, len     addr = 0x10010000
     lw   $3, 4($1)
     sub  $4, $9, $3
     add  $5, $3, $9
     add  $6, $5, $9
     or   $7, $3, $9
 
