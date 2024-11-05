.globl abs

.text
# =================================================================
# FUNCTION: Absolute Value Converter
#
# Transforms any integer into its absolute (non-negative) value by
# modifying the original value through pointer dereferencing.
# For example: -5 becomes 5, while 3 remains 3.
#
# Args:
#   a0 (int *): Memory address of the integer to be converted
#
# Returns:
#   None - The operation modifies the value at the pointer address
# =================================================================
abs:
    # Prologue
    ebreak
    # Load number from memory
    lw t0 0(a0)
    bge t0, zero, done

    # TODO: Add your own implementation
    srai t1, t0, 31    # Arithmetic right shift by 31 to get all 1s if negative, all 0s if positive
    xor t0, t0, t1     # XOR with the mask
    sub t0, t0, t1     # Subtract the mask
    sw t0, 0(a0)       # Store back to memory
done:
    # Epilogue
    jr ra
