.include "syscalls.asm"
.include "bmp_header.asm"
.include "structs.asm"
.include "bmp.asm"
.include "helpers.asm"
.globl main

.eqv	NUMBER_OF_ARGUMENTS	5

	.data
arg_struct:		.space 	20
image_struct:		.space	24
__:			.space 	2
image_struct_header:	.space	BMP_HEADER_T_SIZE
image_struct_image:	.space	IMAGE_MAX_SIZE

input_filename:		.asciz	"examples/tree.bmp"
output_filename:	.asciz 	"output/tree.bmp"

msg_error_arguments:	.asciz 	"Too few arguments / invalid arguments are given"
msg_error_points:	.asciz	"Points are incorect (x1 > x2 or y1 > y2 or points are outside of the image)"
msg_error_image:	.asciz	"Cannot read/write image"
newline:		.asciz	"\n"
comma:			.asciz	","

	.text
main:
main__prologue:
	addi	sp, sp, -16			# Save register s0 - s3
	sw	s0, 0(sp)			
	sw	s1, 4(sp)			
	sw	s2, 8(sp)			
	sw	s3, 12(sp)	
main__body:
	mv	s0, a0				# Save number of arguments
	mv	s1, a1				# Save address to arguments list
	la	s2, arg_struct			# Load address of ArgStruct
	la	s3, image_struct		# Load address of ImageStruct
	
	li	t0, NUMBER_OF_ARGUMENTS		# Check if 5 arguments are given
	bne	a0, t0, main__error_arguments
main__parse_arguments:
	lw	a0, (s1)			# Load the address of the argument
	jal	parse_int			# Parse argument to int
	sw	a0, (s2)			# Store the parsed value in ArgStruct
	blt	a0, zero, main__error_arguments	# Check if parsed value is valid
	addi	s0, s0, -1			# Decrement loop counter
	addi	s1, s1, 4			# Increment the pointer to next argument
	addi 	s2, s2, 4			# Increment the pointer to next field in ArgStruct
	bnez	s0, main__parse_arguments
main__check_arguments:
	la	s2, arg_struct			# Load the ArgStruct address
	lw	t0, ARG_STRUCT_X1(s2)		# Load the value of X1
	lw	t1, ARG_STRUCT_Y1(s2)		# Load the value of Y1
	lw	t2, ARG_STRUCT_X2(s2)		# Load the value of X2
	lw	t3, ARG_STRUCT_Y2(s2)		# Load the value of Y2
	lw	t4, ARG_STRUCT_THRESHOLD(s2)	# Load the threshold value
	li	t5, 256				# Load constant 255
	
	bgeu	t0, t2, main__error_points	# Check if X1 < X2
	bgeu	t1, t3, main__error_points	# Check if Y1 < Y2
	bgeu	t4, t5, main__error_points	# Check if 0 <= threshold <= 255
main__process_image:
	la	t0, image_struct_header		# Load address of header buffer
	la	t1, image_struct_image		# Load address of image buffer
	la	t2, input_filename		# Load address of input filename
	sw	t0, IMAGE_STRUCT_HEADER_DATA(s3)# Set header buffer in ImageStruct
	sw	t1, IMAGE_STRUCT_IMAGE_DATA(s3) # Set image buffer in ImageStruct
	sw	t2, IMAGE_STRUCT_FILENAME(s3)	# Set the filename in ImageStruct
	
	# Read the BMP
	mv	a0, s3				# Load the address of ImageStruct
	jal	bmp_read			# Read BMP from file
	bnez	a0, main__error_image		# Check if return value is valid
	
	# Check if (x2, y2) is in image
	lw	t0, IMAGE_STRUCT_WIDTH(s3)	# Load the width of the image
	lw	t1, IMAGE_STRUCT_HEIGHT(s3)	# Load the height of the image
	lw	t2, ARG_STRUCT_X2(s2)		# Load the value of X2
	lw	t3, ARG_STRUCT_Y2(s2)		# Load the value of Y2
	bgtu	t2, t0, main__error_points	# Error if x2 > width
	bgtu	t3, t1, main__error_points	# Error if y2 > height
	
	# Process the BMP
	la	a0, image_struct		# Load the address of ImageStruct
	la	a1, arg_struct			# Load the address of ArgStruct
	jal	monochrome			# Call the monochrome function
	
	# Write the BMP
	la	a0, image_struct		# Load the address of ImageStruct
	la	t2, output_filename		# Load address of output filename
	sw	t2, IMAGE_STRUCT_FILENAME(a0)	# Set new image filename in ImageStruct
	jal	bmp_write			# Write BMP to file
	bnez	a0, main__error_image		# Check if return value is valid
	
	mv	a0, zero			# Set the exit code to zero
main__epilogue:
	sw	s3, 12(sp)			# Restore register s0 - s3
	sw	s2, 8(sp)			
	sw	s1, 4(sp)			
	sw	s0, 0(sp)			
	addi	sp, sp, 12
	li	a7, SYSTEM_EXIT_CODE		# Terminate the program
	ecall
main__error_arguments:
	li	a7, SYSTEM_PRINT_STRING		# Print the error message in console
	la	a0, msg_error_arguments
	ecall
	li	a0, 2000			# Set the exit code to 2000
	j	main__epilogue			# Exit the function
main__error_points:
	li	a7, SYSTEM_PRINT_STRING		# Print the error message in console
	la	a0, msg_error_points
	ecall
	li	a0, 2001			# Set the exit code to 2001
	j	main__epilogue			# Exit the function
main__error_image:
	li	a7, SYSTEM_PRINT_STRING		# Print the error message in console
	la	a0, msg_error_image
	ecall
	li	a0, 2002			# Set the exit code to 2002
	j	main__epilogue			# Exit the function
	

# monochrome
#	Change the part of the image defined by ArgStruct into monochrome picture
# arguments:
#	a0 - address of the ImageStruct
#	a1 - address of the ArgStruct
# returns:
#	nothing
monochrome:
monochrome__prologue:
monochrome__body:
	# A2 - pointer | A3 - Jump | A4 - End of line | A5 - Threshold * 100 | A6 - Counter
	lw	a2, IMAGE_STRUCT_IMAGE_DATA(a0)
	
	lw	t0, IMAGE_STRUCT_WIDTH(a0)
	lw	t1, IMAGE_STRUCT_HEIGHT(a0)
	lw	t2, IMAGE_STRUCT_LINEBYTES(a0)
	lw	t3, ARG_STRUCT_X1(a1)
	lw	t4, ARG_STRUCT_X2(a1)
	lw	t5, ARG_STRUCT_Y2(a1)
	lw	a6, ARG_STRUCT_Y1(a1)
	
	# Calcula the number of lines to modify
	sub	a6, t5, a6
	
	# Calculate the address of first line to modify
	sub	t6, t1, t5			# LinesToOmmit = Height - Y2
	mul	t6, t6, t2			# BytesToOmmit = LinesToOmmit * LineBytes
	add	a2, a2, t6			# FirstLine = ImageDataAddress + BytesToOmmit
	
	# Calculate the address of first pixel to modify
	add	t6, t3, t3			# BytesToSkip = X1 * 3
	add	t6, t6, t3
	add	a2, a2, t6			# FirstPixel = FirstLine + BytesToSkip
	
	# Calculate the jump between lines
	sub	t6, t0, t4			# LeftSide = Width - X2
	add	t6, t6, t3			# PixelsToJump = LeftSide + X1
	add	a3, t6, t6			# BytesToJump = Both * 3
	add	a3, a3, t6
	
	# Calculate the end of the line
	sub	t6, t4, t3			# X2 - X1
	add	a4, t6, t6			# (X2 - X1) * 3
	add	a4, a4, t6
	
	# Calculate the threshold
	lw	t0, ARG_STRUCT_THRESHOLD(a1)
	
	slli	t0, t0, 2			# Threshold * 100
	slli	t1, t0, 3
	add	t0, t0, t1
	slli	t1, t1, 1
	add	a5, t0, t1

monochrome__process_line:
	# Calculate the end of the line
	add	t0, a2, a4

monochrome__process_pixel:
	# Load pixels
	lbu	t1, 0(a2)			# (B)lue
	lbu	t2, 1(a2)			# (G)reen
	lbu	t3, 2(a2)			# (R)ed
	
	# Calculate the value of threshold
	# > Red
	slli	t4, t3, 2			# Red * 21
	add	t3, t3, t4
	slli	t4, t4, 2
	add	t3, t3, t4
	
	# > Green
	slli	t2, t2, 3			# Green * 72
	slli	t4, t2, 3
	add	t2, t2, t4	

	# > Blue
	add	t4, t1, t1			# Blue * 7
	add	t5, t4, t4
	add	t1, t1, t4
	add	t1, t1, t5
	
	add	t6, t1, t2			# Red * 21 + Green * 72 + Blue * 7
	add	t6, t6, t3
	
	# Check the threshold
	li	t5, 255				# Check the inequality
	bgtu	t6, a5, monochrome__put_pixel
	mv	t5, zero
monochrome__put_pixel:
	sb	t5, 0(a2)			# Save the pixel
	sb	t5, 1(a2)
	sb	t5, 2(a2)

	addi	a2, a2, 3			# Jump to next pixel address
	blt	a2, t0, monochrome__process_pixel# Jump to next pixel
	
	add	a2, a2, a3			# Jump to next line
	addi	a6, a6, -1			# Decrement the line counter
	bnez	a6, monochrome__process_line	# Loop
monochrome__epilogue:
	jr	ra				# Exit the function

