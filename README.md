# Assignment 2: Classify
## Part A: Mathematical function
### abs
We can obtain the absolute value by using bitwise operation.
1. Arithmetic Shift Right(`srai t1, t0, 31`)
* The purpose here is to create a mask in `t1` that depends on the sign of `t0`.
* In RISC-V, an arithmetic shift right replicates the sign bit, so if `t0` is positive (sign bit = 0), t1 will be 0. If `t0` is negative (sign bit = 1), `t1` will be filled with all 1s 
2. XOR with the Mask(`xor t0, t0, t1`)
* If `t0` was positive (`t1` = 0), XORing with 0 has no effect, so t0 remains unchanged.
* If `t0` was negative (`t1` = `0xFFFFFFFF`), XORing flips all bits of `t0`, effectively computing the bitwise complement of `t0`
* After this operation, `t0` is either the original positive value or the bitwise negation of the original negative value.
3. Subtract the Mask (`sub t0, t0, t1`)
* After XORing, if `t0` was negative, it’s now in the form of a bitwise complement. Subtracting `t1` (which is `0xFFFFFFFF`) effectively adds 1, converting `t0` to its positive (absolute) value.
* If `t0` was positive, this operation does nothing since `t1` is 0.
### ReLU
1. `loop_start`
The instruction `beq t1, a1, loop_end` checks that whether `t1` reaches `a1`(the length of vector). `t1` is an index tracking the current element of the vector.
2. load word and calculate
The starting address of the array is `a0`, and we want to access the position of the i-th element. `t1` holds the i-th index so we need to multiple 4 to get the element because of the integer is 4 byte.
Then we need to add the starting address which is `a0` and the corresponding instruction is `add t3, a0, t2`. However, we can load the element by the address with `lw t4, 0(t3)`.
3. Check ReLU value and renew the value
ReLU operation is make the negative input value to be positive. Otherwise, we can skip manipulating it. The corresponding instruction is `bge t4, zero, skip`. Then we write back the negative input value to original address with `zero` value.
### ArgMax
`ArgMax` is a function that finds the index of the maximum element. The corresponding code is shown below.
```c
    beq t2, a1, loop_end
    slli t3, t2, 2              # t3 <- t2 * 4 (sizeof(int))
    add t3, a0, t3              # t3 <- a0 + t2 * 4
    lw t4, 0(t3)                # t4 <- current element
    ble t4, t0, loop_continue   # if current <= max, continue
    mv t0, t4                   # update max
    mv t1, t2                   # update max_index
```
It iterates through each element in the array, and if it encounters a value greater than the current maximum, it updates both the maximum value and its index.
1. `beq t2, a1, loop_end`: Checks if the current index `t2` is equal to the array length `a1`. If they are equal, it means the loop has traversed the entire array, and it jumps to loop_end to exit the loop.
2. `slli t3, t2, 2`: Left shifts `t2` by 2 bits (equivalent to multiplying by 4) to calculate the offset of the current element in the array (assuming each integer is 4 bytes).
3. `add t3, a0, t3`: Adds the offset to the starting address of the array `a0` to get the address of the current element.
4. `lw t4, 0(t3)`: Loads the current element’s value from address `t3` into `t4`.
5. `ble t4, t0, loop_continue`: If the current element is less than or equal to `t0` (the current maximum), it jumps to `loop_continue` to check the next element.
6. `mv t0, t4`: If the current element is greater than the maximum value, it updates the maximum value `t0`.
7. `mv t1, t2`: Updates `t1` to store the index of the new maximum value.
### Dot product
The core functionality of this code is to calculate the dot product of two arrays, where each array has a custom stride. The code iteratively takes each corresponding element from both arrays, multiplies them, and accumulates the results into a running sum.
1. Calculate Element Index Positions
* Using stride1 and stride2 as the strides, it converts the index i into memory addresses.
* The loop uses i as the current element index:
    * It calculates `i * stride1` to get the address of the element in the first array.
    * Similarly, it calculates `i * stride2` to get the address of the element in the second array.
2. Load Elements from Addresses
* The calculated addresses (shifted left with `slli` to match the int data size) are used to access the current elements of the arrays.
* `lw t3, 0(t2)` loads the element from the first array, and `lw t5, 0(t4)` loads the element from the second array, storing them in registers `t3` and `t5`, respectively.
3. Calculate Element Product
* It uses repeated addition to simulate multiplication, calculating `arr1[i * stride1] * arr2[i * stride2]`.
* If `t3` (the element from the first array) is negative, it enters the handle_neg block and takes its absolute value to handle negative values:
    * For positive numbers, it calculates the product by repeatedly adding `t5`.
    * For negative numbers, it simulates multiplication by repeatedly subtracting `t5`.
4. Accumulate into Total Sum
* Finally, it adds the calculated product to t0, which keeps a running total of the dot product.
### Matrix Multiplication
In the matrix multiplication portion of this RISC-V assembly code, the function iterates through each row of the first matrix (`M0`) and each column of the second matrix (`M1`) to compute the dot products that populate the result matrix `D`.
1. Row and Column Iteration
The outer loop (`outer_loop_start`) iterates through each row of `M0`, while the inner loop (`inner_loop_start`) iterates through each column of `M1` for a given row in `M0`.
2. Dot Product Calculation
Inside the inner loop, a helper function (`dot`) is called to compute the dot product of the current row from `M0` and the current column from `M1`. This function:
    * Takes pointers to the current row of `M0` and the ccurrent column of `M1`
    * Multiplies corresponding elements in these vectors and sums them up to produce a single scalar result, representing one element in `D`.
3. Storing Results in `D`
After the dot product calculation, the result (stored in `t0`) is written to the corresponding position in `D` by using the pointer `s2`, which points to the location in `D` for the current row and column combination.
4. Pointer Adjustments
After completing each column iteration for a row in `M0`, the pointer `s3` is advanced to the next row, and `s4` is reset to the beginning of `M1` for the next dot product calculation in the following row.
## Part B: File Operations and Main
### Read Matrix
In `read_matrix.s`, I replace `mul` instruction with my own implementation. And the purpose of `multiply_loop` in this file is to calculate the product of the row and column counts (`t1` and `t2`) without using the `mul` instruction, which may be restricted or unavailable in this environment. Instead, this loop simulates multiplication by using repeated addition.
1. Initialize the Result and Counter
   * `s1` is initialized to `0` to store the final result.
   * `t3` is set to `t1`, the row count, and serves as a counter to ccontrol the loop.
2. Loop: Repeated Addition
   * In each iteration, `t2`(the number of columns) is added to `s1`. This effectively adds `t2`a total of `t1` times, achieving the equivalent of `t1 * t2`.
   * `t3` is then decremented by 1 to move closer to the end of the loop.
3. Loop Termination
   * The loop continues until `t3`(initially set to `t1`) becomes zero, signaling that `t2` has been added `t1` times.

By the end of `multiply_loop`, `s1` holds the total number of elements in the matrix (`t1 * t2`). This result is then shifted by 2 bits (slli t3, s1, 2) to convert the count into bytes (since each maatrix element is 4 bytes).
### Write Matrix
In `write_matrix`, this function will calculate the total number of matrix elements (`s4 = s2 * s3`) without using the `mul` instruction, by implementing multiplication as repeated addition.
1. Initialization
   * `s4` is initialized to `0` and will store the result of `s2 * s3` (total elements).
   * `t0` is set to `s2` (number of rows) and is used as a loop counter.
2. Loop: Repeated Addition
   * Each loop iteration adds `s3` (the number of columns) to `s4`, simulating multiplication. This means `s3` is added `s2` times.
   * `t0` is decremented after each addition to track the number of repetitions (equivalent to the row count).
3. Loop Termination
   * The loop exits once `t0` becomes`0`, at which point `s4` holds the value of `s2 * s3`, representing the total number of elements in the matrix.
This approach replicates mjultiplication by summing `s3` for eacch row, ensuring the final result in `s4` equals `s2 * s3` without using the `mul` instruction.
### Classification
## Result
```bash
test_abs_minus_one (__main__.TestAbs) ... ok
test_abs_one (__main__.TestAbs) ... ok
test_abs_zero (__main__.TestAbs) ... ok
test_argmax_invalid_n (__main__.TestArgmax) ... ok
test_argmax_length_1 (__main__.TestArgmax) ... ok
test_argmax_standard (__main__.TestArgmax) ... ok
test_chain_1 (__main__.TestChain) ... ok
test_classify_1_silent (__main__.TestClassify) ... ok
test_classify_2_print (__main__.TestClassify) ... ok
test_classify_3_print (__main__.TestClassify) ... ok
test_classify_fail_malloc (__main__.TestClassify) ... ok
test_classify_not_enough_args (__main__.TestClassify) ... ok
test_dot_length_1 (__main__.TestDot) ... ok
test_dot_length_error (__main__.TestDot) ... ok
test_dot_length_error2 (__main__.TestDot) ... ok
test_dot_standard (__main__.TestDot) ... ok
test_dot_stride (__main__.TestDot) ... ok
test_dot_stride_error1 (__main__.TestDot) ... ok
test_dot_stride_error2 (__main__.TestDot) ... ok
test_matmul_incorrect_check (__main__.TestMatmul) ... ok
test_matmul_length_1 (__main__.TestMatmul) ... ok
test_classify_2_print (__main__.TestClassify) ... ok
test_classify_3_print (__main__.TestClassify) ... ok
test_classify_fail_malloc (__main__.TestClassify) ... ok
test_classify_not_enough_args (__main__.TestClassify) ... ok
test_dot_length_1 (__main__.TestDot) ... ok
test_dot_length_error (__main__.TestDot) ... ok
test_dot_length_error2 (__main__.TestDot) ... ok
test_dot_standard (__main__.TestDot) ... ok
test_dot_stride (__main__.TestDot) ... ok
test_dot_stride_error1 (__main__.TestDot) ... ok
test_dot_stride_error2 (__main__.TestDot) ... ok
test_matmul_incorrect_check (__main__.TestMatmul) ... ok
test_matmul_length_1 (__main__.TestMatmul) ... ok
test_classify_3_print (__main__.TestClassify) ... ok
test_classify_fail_malloc (__main__.TestClassify) ... ok
test_classify_not_enough_args (__main__.TestClassify) ... ok
test_dot_length_1 (__main__.TestDot) ... ok
test_dot_length_error (__main__.TestDot) ... ok
test_dot_length_error2 (__main__.TestDot) ... ok
test_dot_standard (__main__.TestDot) ... ok
test_dot_stride (__main__.TestDot) ... ok
test_dot_stride_error1 (__main__.TestDot) ... ok
test_dot_stride_error2 (__main__.TestDot) ... ok
test_matmul_incorrect_check (__main__.TestMatmul) ... ok
test_matmul_length_1 (__main__.TestMatmul) ... ok
test_classify_not_enough_args (__main__.TestClassify) ... ok
test_dot_length_1 (__main__.TestDot) ... ok
test_dot_length_error (__main__.TestDot) ... ok
test_dot_length_error2 (__main__.TestDot) ... ok
test_dot_standard (__main__.TestDot) ... ok
test_dot_stride (__main__.TestDot) ... ok
test_dot_stride_error1 (__main__.TestDot) ... ok
test_dot_stride_error2 (__main__.TestDot) ... ok
test_matmul_incorrect_check (__main__.TestMatmul) ... ok
test_matmul_length_1 (__main__.TestMatmul) ... ok
test_dot_length_error2 (__main__.TestDot) ... ok
test_dot_standard (__main__.TestDot) ... ok
test_dot_stride (__main__.TestDot) ... ok
test_dot_stride_error1 (__main__.TestDot) ... ok
test_dot_stride_error2 (__main__.TestDot) ... ok
test_matmul_incorrect_check (__main__.TestMatmul) ... ok
test_matmul_length_1 (__main__.TestMatmul) ... ok
test_dot_stride (__main__.TestDot) ... ok
test_dot_stride_error1 (__main__.TestDot) ... ok
test_dot_stride_error2 (__main__.TestDot) ... ok
test_matmul_incorrect_check (__main__.TestMatmul) ... ok
test_matmul_length_1 (__main__.TestMatmul) ... ok
test_dot_stride_error2 (__main__.TestDot) ... ok
test_matmul_incorrect_check (__main__.TestMatmul) ... ok
test_matmul_length_1 (__main__.TestMatmul) ... ok
test_matmul_length_1 (__main__.TestMatmul) ... ok
test_matmul_negative_dim_m0_x (__main__.TestMatmul) ... ok
test_matmul_negative_dim_m0_x (__main__.TestMatmul) ... ok
test_matmul_negative_dim_m0_y (__main__.TestMatmul) ... ok
test_matmul_negative_dim_m1_x (__main__.TestMatmul) ... ok
test_matmul_negative_dim_m1_y (__main__.TestMatmul) ... ok
test_matmul_nonsquare_1 (__main__.TestMatmul) ... ok
test_matmul_nonsquare_2 (__main__.TestMatmul) ... ok
test_matmul_nonsquare_outer_dims (__main__.TestMatmul) ... ok
test_matmul_square (__main__.TestMatmul) ... ok
test_matmul_unmatched_dims (__main__.TestMatmul) ... ok
test_matmul_zero_dim_m0 (__main__.TestMatmul) ... ok
test_matmul_zero_dim_m1 (__main__.TestMatmul) ... ok
test_read_1 (__main__.TestReadMatrix) ... ok
test_read_2 (__main__.TestReadMatrix) ... ok
test_read_3 (__main__.TestReadMatrix) ... ok
test_read_fail_fclose (__main__.TestReadMatrix) ... ok
test_read_fail_fopen (__main__.TestReadMatrix) ... ok
test_read_fail_fread (__main__.TestReadMatrix) ... ok
test_read_fail_malloc (__main__.TestReadMatrix) ... ok
test_relu_invalid_n (__main__.TestRelu) ... ok
test_relu_length_1 (__main__.TestRelu) ... ok
test_relu_standard (__main__.TestRelu) ... ok
test_write_1 (__main__.TestWriteMatrix) ... ok
test_write_fail_fclose (__main__.TestWriteMatrix) ... ok
test_write_fail_fopen (__main__.TestWriteMatrix) ... ok
test_write_fail_fwrite (__main__.TestWriteMatrix) ... ok

----------------------------------------------------------------------
Ran 46 tests in 99.760s

OK
```
