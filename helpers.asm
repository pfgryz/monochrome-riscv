	.text
# parse_int
# 	Parse string to int
# arguments:
#	a0 - address of the string
# returns:
#	a0 - -1 if error, otherwise the parsed number
parse_int:
parse_int__prologue:
parse_int__body:
	mv	t0, a0				# Save the address of the string
	mv	a0, zero			# Initialize output with zero
	li	t5, '0'				# Load constant '0'
	li	t6, '9'				# Load constant '9'
parse_int__next_char:
	lbu	t1, (t0)			# Load the char from the string
	addi	t0, t0, 1			# Increment the pointer to next char
	beqz	t1, parse_int__epilogue		# Jump to epilogue if char is NULL
	bgtu	t1, t6, parse_int__error	# Error if char is greater than '9'
	bltu	t1, t5, parse_int__error	# Error if char is lower than '0'
	
	add	a0, a0, a0			# number * 2
	add	a1, a0, a0			# number * 4
	add	a1, a1, a1			# number * 8
	add	a0, a0, a1			# number * 10
	
	add	a0, a0, t1			# Calculate new value of the number
	sub	a0, a0, t5
	j	parse_int__next_char
parse_int__epilogue:
	jr	ra				# Exit the function
parse_int__error:
	li	a0, -1				# Set the return value to -1
	jr	ra				# Exit the function
	
