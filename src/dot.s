.globl dot

.text
# =======================================================
# FUNCTION: Strided Dot Product Calculator
#
# Calculates sum(arr0[i * stride0] * arr1[i * stride1])
# where i ranges from 0 to (element_count - 1)
#
# Args:
#   a0 (int *): Pointer to first input array
#   a1 (int *): Pointer to second input array
#   a2 (int):   Number of elements to process
#   a3 (int):   Skip distance in first array
#   a4 (int):   Skip distance in second array
#
# Returns:
#   a0 (int):   Resulting dot product value
#
# Preconditions:
#   - Element count must be positive (>= 1)
#   - Both strides must be positive (>= 1)
#
# Error Handling:
#   - Exits with code 36 if element count < 1
#   - Exits with code 37 if any stride < 1
# =======================================================
dot:
    li t0, 1
    blt a2, t0, error_terminate  
    blt a3, t0, error_terminate   
    blt a4, t0, error_terminate  

    li t0, 0            
    li t1, 0         

loop_start:
    bge t1, a2, loop_end
    # TODO: Add your own implementation
    # Calculate i * stride1 for first array
    mv t2, t1           # t2 = i
    li t6, 0           # Initialize result
    beqz t2, skip_mult1
mult1_loop:
    add t6, t6, a3     # Add stride1
    addi t2, t2, -1    # Decrement counter
    bnez t2, mult1_loop
skip_mult1:
    mv t2, t6          # t2 = i * stride1
    slli t2, t2, 2     # t2 = (i * stride1) * 4
    add t2, a0, t2     # t2 = &arr1[i * stride1]
    lw t3, 0(t2)       # t3 = arr1[i * stride1]
    
    # Calculate i * stride2 for second array
    mv t4, t1          # t4 = i
    li t6, 0           # Initialize result
    beqz t4, skip_mult2
mult2_loop:
    add t6, t6, a4     # Add stride2
    addi t4, t4, -1    # Decrement counter
    bnez t4, mult2_loop
skip_mult2:
    mv t4, t6          # t4 = i * stride2
    slli t4, t4, 2     # t4 = (i * stride2) * 4
    add t4, a1, t4     # t4 = &arr2[i * stride2]
    lw t5, 0(t4)       # t5 = arr2[i * stride2]
    
    # Multiply elements using repeated addition
    li t6, 0           # Initialize product
    mv t4, t3          # Copy first number
    bltz t4, handle_neg # Handle negative number
pos_mult:
    beqz t4, skip_mult3
mult3_loop:
    add t6, t6, t5     # Add second number
    addi t4, t4, -1    # Decrement counter
    bnez t4, mult3_loop
    j skip_mult3
handle_neg:
    neg t4, t4         # Make positive
neg_mult_loop:
    sub t6, t6, t5     # Subtract instead of add for negative
    addi t4, t4, -1
    bnez t4, neg_mult_loop
skip_mult3:

    add t0, t0, t6     # sum += product
    
    addi t1, t1, 1     # Increment counter
    j loop_start

loop_end:
    mv a0, t0
    jr ra

error_terminate:
    blt a2, t0, set_error_36
    li a0, 37
    j exit

set_error_36:
    li a0, 36
    j exit
