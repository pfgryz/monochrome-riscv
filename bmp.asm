.eqv	IMG_INFO_FILENAME		0
.eqv	IMG_INFO_HEADER_DATA		4
.eqv	IMG_INFO_IMAGE_DATA		8
.eqv	IMG_INFO_WIDTH			12
.eqv	IMG_INFO_HEIGHT			16
.eqv	IMG_INFO_LINE_SIZE		20
.eqv	MAX_IMG_SIZE			230400


	.text
# bmp_read
# 	Reads the content of the BMP file
# arguments:
#	a0 - address of the ImageStruct
# returns:
#	a0 - 0 if successful, otherwise the error code
# error codes:
#	0x1001 - cannot open the file for read
bmp_read:
bmp_read__prologue:
bmp_read__body:
	mv	t6, a0				# Save the address of ImageStruct
	
	# Open file
	li	a7, SYSTEM_OPEN_FILE		# Set syscall code to open file
	lw	a0, IMAGE_STRUCT_FILENAME(t6)	# Load filename address
	li	a1, 0				# Set mode to read
	ecall					# Call
	
	blt	a0, zero, bmp_read__error	# Test if operation is successful
	mv	t0, a0				# Save the file descriptor address
	
	# Read BMP header
	li	a7, SYSTEM_READ_FILE		# Set syscall code to read file
	lw	a1, IMAGE_STRUCT_HEADER_DATA(t6)# Load address of buffer
	li	a2, BMP_HEADER_T_SIZE		# Set maximum length to read
	ecall					# Call
	
	# Update the ImageStruct
	lw	a0, BMP_HEADER_HEIGHT(a1)	# Extract the image height from the BMP file
	sw	a0, IMAGE_STRUCT_HEIGHT(t6)	# Save the image height into ImageStruct
	
	lw	a0, BMP_HEADER_WIDTH(a1)	# Extract the image width from the BMP file
	sw	a0, IMAGE_STRUCT_WIDTH(t6)	# Save the image width into ImageStruct
	
	add	a2, a0, a0			# Calculate number of the occupied bytes by pixel 
	add	a0, a2, a0			# Calculate number of the occupied bytes by pixel (bytes = pixels * 3)
	addi	a0, a0, 3			# bytes += 3
	srai	a0, a0, 2			# bytes //= 4
	slli	a0, a0, 2			# bytes *= 4
	sw	a0, IMAGE_STRUCT_LINEBYTES(t6)	# Save the amount of bytes in line into ImageStruct
	
	# Read BMP image data
	mv	a0, t0				# Load the file descriptor
	
	li	a7, SYSTEM_READ_FILE		# Set syscall code to read file
	lw	a1, IMAGE_STRUCT_IMAGE_DATA(t6) # Load address of the buffer
	li	a2, IMAGE_MAX_SIZE		# Set maximum length to read
	ecall					# Call
		
	# Close file
	li	a7, SYSTEM_CLOSE_FILE		# Set syscall code to close file
	mv	a0, t6				# Load address of file descriptor to close
	ecall					# Call
	
	li	a0, 0				# Set return value to 0
bmp_read__epilogue:
	jr	ra				# Exit the function
bmp_read__error:
	li	a0, 0x1001			# Set the error code to 0x1001
	jr	ra				# Exit the function
	

# bmp_write
#	Writes the content of the BMP file in memory to a file
# arguments:
# 	a0 - address of the ImageStruct
# returns:
#	a0 - 0 if successful, otherwise the error code
# error codes:
#	0x1002 - cannot open the file for write
bmp_write:
bmp_write__prologue:
bmp_write__body:
	mv	t6, a0				# Save the address of ImageStruct
	
	# Open file
	li	a7, SYSTEM_OPEN_FILE		# Set syscall code to open file
	lw	a0, IMAGE_STRUCT_FILENAME(t6)	# Load filename address
	li	a1, 1				# Set mode to write
	ecall					# Call
	
	blt	a0, zero, bmp_read__error	# Test if operation is successful
	mv	t0, a0				# Save the file descriptor address
	
	# Write BMP header
	li	a7, SYSTEM_WRITE_FILE		# Set syscall code to write file
	lw	a1, IMAGE_STRUCT_HEADER_DATA(t6)# Load address of buffer
	li	a2, BMP_HEADER_T_SIZE		# Set maxium length to write
	ecall					# Call
	
	# Write BMP image data
	mv	a0, t0				# Load the file descriptor
	lw	t1, IMAGE_STRUCT_HEADER_DATA(t6)# Load the header of the image
	
	li	a7, SYSTEM_WRITE_FILE		# Set syscall code to write file
	lw	a1, IMAGE_STRUCT_IMAGE_DATA(t6)	# Load address of buffer
	lw	a2, BMP_HEADER_IMAGE_SIZE(t1)	# Set maxium length to write
	ecall					# Call
	
	# Close file
	li	a7, SYSTEM_CLOSE_FILE		# Set syscall code to close file
	mv	a0, t6				# Load address of file descriptor to close
	ecall					# Call
	
	li	a0, 0				# Set return value to zero
bmp_write__epilogue:
	jr	ra				# Exit the function
bmp_write__error:
	li	a0, 0x1002			# Set the error code to 0x1002
	jr	ra				# Exit the function
