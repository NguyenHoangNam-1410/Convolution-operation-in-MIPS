.data
	.align 2
	input_file: .asciiz "test_7.txt"
	output_file: .asciiz "output_matrix.txt"
	buffer_read: .space 2048
	buffer_write: .space 1024
	invalid: .asciiz "invalid input"
	newline: .asciiz "\n"
	space: .asciiz " "
	fp0: .float 0.0
	fp10: .float 10.0
	fp1: .float -1.0
          # Arrays to store image, kernel and out matrices
	image: .word 0:100
	image_with_padding: .word 0:228
	kernel: .word 0:100
	out: .word 0:64
	
.text
	li $v0, 13
	la $a0 , input_file 
	li $a1 , 0 
	li $a2 , 0 
	syscall 
	
	move $t0 , $v0 
	beqz $t0, invalid_input
	li $v0 , 14 
	move $a0 , $t0
	la $a1 , buffer_read 
	li $a2 , 2048 
	syscall 
	
	la $t0, buffer_read #read[0]
	lb $s0, ($t0) #s0 = N
	sub $s0, $s0, '0'
	
	addi $t0, $t0, 2
	lb $s1, ($t0) #s1 = M
	sub $s1, $s1, '0'

	addi $t0, $t0, 2
	lb $s2, ($t0) #s2 = p
	sub $s2, $s2, '0'

	addi $t0, $t0, 2
	lb $s3, ($t0) #s3 = s
	sub $s3, $s3, '0'
	
	sll $t1, $s2, 1 #p x 2
	add $t2, $s0, $t1 #N + p x 2
	blt $t2, $s1, invalid_input # N + p x 2 < M => invalid
	#first line is done
	li $s4, 0 #bool negative
	li $s5, 0 #bool decimal
	addi $t0, $t0, 3 #next line
	mul $t7, $s0, $s0 #NxN = t7
	la $s6, image
	
read_image:
	lb $t1, ($t0) #read[n]
	beq $t1, '-', negative_route_image
	beq $t1, ' ', convert_float_image
	sub $t1, $t1, '0' #convert char to int in $t1
	addi $t0, $t0, 1 #read[n + 1]
	lb $t2, ($t0) #next char
	beq $t2, '.', decimal_route_image1 #if read[n] = '.' go to decimal with single natural
	beq $t2, ' ', convert_float #if read[n] = ' ' go to convert with single natural
	beq $t2, 13, convert_float
	#2 digits value
	sub $t2, $t2, '0' #convert char to int in $t2
	mul $t1, $t1, 10
	add $t1, $t2, $t1
	mtc1 $t1, $f0
	cvt.s.w $f0, $f0 #f0 store double natural
	addi $t0, $t0, 1 #read[n+1]
	lb $t2, ($t0)
	beq $t2, '.', decimal_route_image2 #convert double natural with decimal
	j convert_float_image #convert with double natural
	
negative_route_image:
	addi $s4, $s4, 1 #negative
	addi $t0, $t0, 1 #read[n + 1]
	j read_image
	
negative_solve_image:
	addi $s4, $s4, -1
	l.s $f3, fp1 #-1.0
	mul.s $f0, $f0, $f3 #number * -1.0
	j convert_float_image
	
decimal_route_image1:
	addi $s5, $s5, 1 #bool = true
	mtc1 $t1, $f0
	cvt.s.w $f0, $f0 #f0 store natural
	addi $t0, $t0, 1 #read[n+1]
	lb $t4, ($t0) #get decimal
	sub $t4, $t4, '0' #convert char to int
	mtc1 $t4, $f1 #move int to cp
	cvt.s.w $f1, $f1 #convert int to float
	l.s $f10, fp10 #f10 = 10.0
	div.s $f1, $f1, $f10 #$f1 / 10.0
	addi $t0, $t0, 1 #read[n+1]
	j convert_float_image
	
decimal_route_image2:
	addi $s5, $s5, 1 #bool = true
	addi $t0, $t0, 1 #read[n+1]
	lb $t4, ($t0) #get decimal
	sub $t4, $t4, '0' #convert char to int
	mtc1 $t4, $f1 #move int to cp
	cvt.s.w $f1, $f1 #convert int to float
	l.s $f10, fp10 #f10 = 10.0
	div.s $f1, $f1, $f10 #$f1 / 10.0
	addi $t0, $t0, 1 #read[n+1]
	j convert_float_image

decimal_solve_image:
	addi $s5, $s5, -1
	add.s $f0, $f0, $f1 #natural + decimal
	j convert_float_image
	
convert_float_image: #double digits convert
	beq $s5, 1, decimal_solve_image
	beq $s4, 1, negative_solve_image
	s.s $f0, ($s6)
	addi $s6, $s6, 4
	addi $t7, $t7, -1 #number of image elements
	beqz $t7, last_line
	addi $t0, $t0, 1
	j read_image
	
convert_float: #single digit convert
	mtc1 $t1, $f0
	cvt.s.w $f0, $f0 #f0 store natural
	beq $s4, 1, negative_solve_image
	s.s $f0, ($s6)
	addi $s6, $s6, 4
	addi $t7, $t7, -1 #number of image elements
	beqz $t7, last_line
	addi $t0, $t0, 1
	j read_image
	
last_line:
	li $s4, 0 #bool negative
	li $s5, 0 #bool decimal
	addi $t0, $t0, 2 #last line
	mul $t7, $s1, $s1 #MxM = t7
	la $s7, kernel
	
read_kernel:
	lb $t1, ($t0) #read[n]
	beq $t1, '-', negative_route_kernel
	beq $t1, ' ', convert_float_kernel
	sub $t1, $t1, '0' #convert char to int in $t1
	addi $t0, $t0, 1 #read[n + 1]
	lb $t2, ($t0) #next char
	beq $t2, '.', decimal_route_kernel1 #if read[n] = '.' go to decimal with single natural
	beq $t2, ' ', convert_float2 #if read[n] = ' ' go to convert with single natural
	beq $t2, 0, convert_float2 #if read end
	#2 digits value
	sub $t2, $t2, '0' #convert char to int in $t2
	mul $t1, $t1, 10
	add $t1, $t2, $t1
	mtc1 $t1, $f0
	cvt.s.w $f0, $f0 #f0 store double natural
	addi $t0, $t0, 1 #read[n+1]
	lb $t2, ($t0)
	beq $t2, '.', decimal_route_kernel2 #convert double natural with decimal
	j convert_float_kernel #convert with double natural
	
negative_route_kernel:
	addi $s4, $s4, 1 #negative
	addi $t0, $t0, 1 #read[n + 1]
	j read_kernel
	
negative_solve_kernel:
	addi $s4, $s4, -1 #bool = false
	l.s $f3, fp1 #-1.0
	mul.s $f0, $f0, $f3 #number * -1.0
	j convert_float_kernel

decimal_route_kernel1:
	addi $s5, $s5, 1 #bool = true
	mtc1 $t1, $f0
	cvt.s.w $f0, $f0 #f0 store natural
	addi $t0, $t0, 1 #read[n+1]
	lb $t4, ($t0) #get decimal
	sub $t4, $t4, '0' #convert char to int
	mtc1 $t4, $f1 #move int to cp
	cvt.s.w $f1, $f1 #convert int to float
	l.s $f10, fp10 #f10 = 10.0
	div.s $f1, $f1, $f10 #$f1 / 10.0
	addi $t0, $t0, 1 #read[n+1]
	j convert_float_kernel
	
decimal_route_kernel2:
	addi $s5, $s5, 1 #bool = true
	addi $t0, $t0, 1 #read[n+1]
	lb $t4, ($t0) #get decimal
	sub $t4, $t4, '0' #convert char to int
	mtc1 $t4, $f1 #move int to cp
	cvt.s.w $f1, $f1 #convert int to float
	l.s $f10, fp10 #f10 = 10.0
	div.s $f1, $f1, $f10 #$f1 / 10.0
	addi $t0, $t0, 1 #read[n+1]
	j convert_float_kernel
	
decimal_solve_kernel:
	addi $s5, $s5, -1 #bool = false
	add.s $f0, $f0, $f1 #natural + decimal
	j convert_float_kernel
	
convert_float_kernel: #double digits convert
	beq $s5, 1, decimal_solve_kernel
	beq $s4, 1, negative_solve_kernel
	s.s $f0, ($s7)
	addi $s7, $s7, 4
	addi $t7, $t7, -1 #number of kernel elements
	beqz $t7, padding	
	addi $t0, $t0, 1
	j read_kernel
	
convert_float2: #single digit convert
	mtc1 $t1, $f0
	cvt.s.w $f0, $f0 #f0 store natural
	beq $s4, 1, negative_solve_kernel
	s.s $f0, ($s7)
	addi $s7, $s7, 4
	addi $t7, $t7, -1 #number of kernel elements
	beqz $t7, padding	
	addi $t0, $t0, 1
	j read_kernel

padding:	
	li $v0, 16 #close file
	move $a0, $t0
	syscall
	sll $t1, $s2, 1 #p x 2
	add $t1, $s0, $t1 #N + p x 2 (number of 0 of first row) = $t1 
	add $t5, $s0, 1 #number of image row copy 
	mul $t5, $s0, $t5 #row = (N+1)xN
	la $t0, image #t0 = image[0]
	la $t2, image_with_padding
	beqz $s2, transfer_image
	mul $t4, $t1, $s2 # (N + px2 ) x p 
	addi $t4, $t4, 1 # $t4 + 1 
	add $t7, $t4, $s2 #for last line
	l.s $f0, fp0 #float 0
	
first_line_padding:
	addi $t4, $t4, -1
	addi $t3, $s2, 1  #p copy 
	beqz $t4, push_zero
	s.s $f0, ($t2)
	addi $t2, $t2, 4
	j first_line_padding
	
push_image:
	add $t3, $s2, $s2 # $t3 = p * 2
	addi $t3, $t3, 1 #p * 2 + 1
	addi $t5, $t5, -1 #sub row - 1 to check if image is done
	beqz $t5, last_line_padding
	addi $t6, $t6, -1 #col - 1 to check if col is done
	beqz $t6, push_zero
	l.s $f1, ($t0) #load element img
	s.s $f1, ($t2) #store to img_padding
	addi $t2, $t2, 4 #next img_padding
	addi $t0, $t0, 4 #next img
	j push_image
	
push_zero: #row = t5, col = t6
	addi $t6, $s0, 1 #number of img column copy
	addi $t3, $t3, -1 #p--
	beqz $t3, push_image
	s.s $f0, ($t2)
	addi $t2, $t2, 4
	j push_zero
	
last_line_padding:	# (N + p x 2) x p + p remaining zero
	addi $t7, $t7, -1
	beqz $t7, striding
	s.s $f0, ($t2)
	addi $t2, $t2, 4
	j last_line_padding
	
transfer_image: #push image to image with padding but no padding
	addi $t5, $t5, -1
	beqz $t5, striding
	l.s $f0, ($t0)
	s.s $f0, ($t2)
	addi $t0, $t0, 4
	addi $t2, $t2, 4
	j transfer_image
	#Padding completed
striding: #Prepare data for convolution #s0, s1, s3 in use
	li $s4, 0 #i = 0
	sll $s2, $s2, 1 #p x 2
	addi $s7, $s0, 0 #copy img size
	add $s7, $s7, $s2 #new img size (N + p x 2)
	sub $s0, $s0, $s1 #N - M
	add $s2, $s0, $s2 #N - M + p x 2
	div $s2, $s3 # (N - M + p x 2) / stride
	mflo $s2
	addi $s2, $s2, 1 # (N - M + p x 2) / stride + 1 is output size
	addi $s0, $s7, 0 #bring new size back to s0
	la $t0, image_with_padding
	la $t1, kernel
	la $t2, out
	
#CONVOLUTION LOOPS
convolve_loop1:
	li $s5, 0 #j = 0
	addi $s7, $s7, 1
convolve_loop2:
	l.s $f0, fp0 #sum = 0
	li $t3, 0 #ki = 0
convolve_loop3:
	li $t4, 0 #kj = 0
convolve_loop4:
	mul $t5, $s3, $s4 # i * s
	add $t5, $t5, $t3 #imageX = i * s + ki
	mul $t6, $s3, $s5 # j * s
	add $t6, $t6, $t4 #imageY = j * s + kj
	mul $t5, $t5, $s0 #imageX * rowsize
	add $t5, $t5, $t6 #imageX * rowsize + imageY
	sll $t5, $t5, 2 #byte 4
	add $t5, $t5, $t0 #get *img[imageX][imageY]
	l.s $f1, ($t5) #get img[imageX][imageY] = f1
	mul $t6, $t3, $s1 #ki * N
	add $t6, $t6, $t4 #ki * N + kj
	sll $t6, $t6, 2 #byte 4
	add $t6, $t6, $t1 #get *kernel[ki][kj]
	l.s $f2, ($t6) #get kernel[ki][kj]
	mul.s $f1, $f1, $f2 #img[imageX][imageY] * kernel[ki][kj]
	add.s $f0, $f0, $f1 #sum += img[imageX][imageY] * kernel[ki][kj]
	
	addiu $t4, $t4, 1 #kj ++
	bne $t4, $s1, convolve_loop4
	addiu $t3, $t3, 1 #ki ++
	bne $t3, $s1, convolve_loop3
	
	mul $t8, $s4, $s2 #i * outSize
	add $t8, $t8, $s5 #i * outSize + j
	sll $t8, $t8, 2 #byte 4
	add $t8, $t8, $t2 #get *out[i][j]
	s.s $f0, ($t8) #store out[i][j]
	
	addiu $s5, $s5, 1 #j++
	bne $s5, $s2, convolve_loop2 #if j = N go back to convolve_loop2
	addiu $s4, $s4, 1 #i++
	bne $s4, $s2, convolve_loop1
#END CONVOLUTION
#jal test_here
output:
	li $v0, 13
	la $a0, output_file
	li $a1, 1
	li $a2, 0
	syscall
	move $s0, $v0
	beqz $s0, invalid_input
	li $s1, 0 #row (i)
	
loop_out1:
	beq $s1, $s2, exit #s2 store out matrix size
	li $s3, 0 #col (j)
	
loop_out2:
	beq $s3, $s2, next_row
	mul $t0, $s1, $s2 #i * size
	add $t0, $t0, $s3 #i * size + j
	sll $t0, $t0, 2  #byte 4
	la $t1, out
	add $t1, $t1, $t0
	l.s $f12, ($t1)
	la $s4, buffer_write
	mtc1 $0, $f0
	c.lt.s $f12, $f0
	bc1f positive_num
	li $t4, 45 # ASCII '-' sb $t4, ($s4)
	sb $t4, ($s4)
	addi $s4, $s4, 1
	
positive_num:
	li $t3, 0
	li $t4, 10
	# Float to Int
	abs.s $f12, $f12 # Absolute value
	trunc.w.s $f0, $f12
	mfc1 $s5, $f0 # Save int part
	# Count digits
	move $t2, $s5
	# Handle zero case
	bnez $t2, count_digit
	li $t3, 1 #index pos
	j store_digit
	
count_digit: #Count int digit
	div $t2, $t4 #int / 10 to take quotient
	addi $t3, $t3, 1 # counter int
	mflo $t2	
	bnez $t2, count_digit #if quotient not zero, continue process int / 10
	
store_digit: #Store counter int digit
	add $t7, $s4, $t3 # Calculate end position
	addi $t7, $t7, -1 
	move $t2, $s5 # Integer value
	move $s4, $t7 # Move to end
	
loop_out3: #store digit to buffer
	l.s $f2, fp10 # Load 10.0
	div $t2, $t4 # int / 10
	mfhi $t5 # get remainder
	addi $t5, $t5, 48 # Convert to ASCII
	sb $t5, ($s4) # Store digit to $s4
	addi $s4, $s4, -1 # Backward
	mflo $t2 #check quotient
	bnez $t2, loop_out3 #loop back
	addi $s4, $t7, 1 # Move pointer after number
# Add decimal point
	li $t5, 46 # '.' sb $t5, ($s4)
	sb $t5, ($s4) 
	addi $s4, $s4, 1
# Process decimal part
	cvt.s.w $f0, $f0
	sub.s $f0, $f12, $f0 # Get decimal part
	abs.s $f0, $f0
	li $t4, 4 #4 digit after floating point
	
loop_out4:
	mul.s $f0, $f0, $f2 #float * 10
	trunc.w.s $f3, $f0 #convert float to int
	mfc1 $t5, $f3 #move to t5
	addi $t5, $t5, 48 # Convert to ASCII
	sb $t5, ($s4)
	cvt.s.w $f3, $f3 #convert back to float
	sub.s $f0, $f0, $f3 #old float - new int (1.043 - 1)
	addi $s4, $s4, 1
	addi $t4, $t4, -1
	bnez $t4, loop_out4
# Add spaces for visualization
	la $t7, buffer_write # Start of string
	sub $t8, $s4, $t7 # Current length
	li $t6, 10 # Total desired width
	sub $t6, $t6, $t8 # Required pad
	
spaces:
	beq $t6, $0, write_result
	li $t5, 32 # ASCII space
	sb $t5, ($s4)
	addi $t6, $t6, -1
	addi $s4, $s4, 1
	j spaces
	
write_result:
	addi $s3, $s3, 1 # Next column
	li $v0, 15
	move $a0, $s0 # File descriptor
	la $a1, buffer_write # String buffer
	sub $a2, $s4, $a1 # Length hardcode
	syscall
	j loop_out2
	
next_row:
	addi $s1, $s1, 1 # Next row
	li $v0, 15
	move $a0, $s0
	la $a1, newline
	li $a2, 1
	syscall
	j loop_out1

test_here: #function to debug matrix
	la $t0, image
	li $t1, 25
	li $t2, 0
print:
	l.s $f12, ($t0)
	li $v0, 2
	syscall
	li $v0, 4
	la $a0, space
	syscall
	addi $t0, $t0, 4
	addi $t2, $t2, 1
	bne $t2, $t1, print
	jr $ra

invalid_input:
	li $v0, 4
	la $a0, invalid
	syscall

exit:
	li $v0, 16
	move $s0, $s0
	syscall
	li $v0, 10
	syscall