##################################################################### 
# 
# CSCB58 Winter 2023 Assembly Final Project 
# University of Toronto, Scarborough 
# 
# Student: Risheit Munshi, 1007968380, munshiri, munshiri@mail.utoronto.ca 
# 
# Bitmap Display Configuration: 
# - Unit width in pixels: 4 (update this as needed)  
# - Unit height in pixels: 4 (update this as needed) 
# - Display width in pixels: 64 (update this as needed) 
# - Display height in pixels: 128 (update this as needed) 
# - Base Address for Display: 0x10008000 ($gp) 
# 
# Which milestones have been reached in this submission? 
# (See the assignment handout for descriptions of the milestones) 
# - Milestone 1/2/3 (choose the one the applies) 
# 
# Which approved features have been implemented for milestone 3? 
# (See the assignment handout for the list of additional features) 
# 1. (fill in the feature, if any) 
# 2. (fill in the feature, if any) 
# 3. (fill in the feature, if any) 
# ... (add more if necessary) 
# 
# Link to video demonstration for final submission: 
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it! 
# 
# Are you OK with us sharing the video with people outside course staff? 
# - yes
# 
# Any additional information that the TA needs to know: 
# - (write here, if any) 
# 
##################################################################### 

#####################################################################
# Conventions:
# - Naming labels:
#    - Function labels to be accessible globally are labelled normally
#    - Inner labels to be accessed within a function only are labelled as
#			xxxx_label_name
#      where xxxx is a 4-letter code uniquely based off the function's name
#      for example, the code for the main function has the code 'main' attached
#      to each of it's labels.
# - Argument registers: ($a0 - $a3): These registers may be modified by the 
#   calling function, unless the function ends in a '_c'. Functions who's names 
#   end in '_c' do not modify the arguments passed into them.
# - Evaluation registers: ($v0, $v1): These registers may be modifed by the calling
#   function to be the function's return value.
#####################################################################

.data 

######################### SYSTEM CONSTANTS ##########################

# BITMAP DETAILS
.eqv WIDTH 64		# Width of the bitmap display in pixels
.eqv WIDTH_S 6		# The shift equivalent to scaling by width (val * WIDTH == val << WIDTH_S)
.eqv HEIGHT 128		# Height of the bitmap display in pixels
.eqv UNIT 4		# Size of one unit in pixels
.eqv UNIT_S 2		# The shift equivalent to scaling by a unit (val * UNIT == val << UNIT_S)

# COLOURS 
.eqv WHITE 		0x00ffffff
.eqv BLACK		0x00000000

.eqv PLAYER_HEAD 	0x00ffb100
.eqv PLAYER_BODY 	0x00bA6314
.eqv PLAYER_LEGS 	0x00146aba

.eqv BLOCKABLE    	0x009fb8cf  # This colour represents objects that the player 
				    # can collide with safely, and blocks the player's path.
.eqv DAMAGING		0x00a60828  # This colour represents objects that damage the player
				    # upon collision.

# KEYPRESSES
.eqv INPUT 0xffff0000
.eqv KEY_W 0x77
.eqv KEY_A 0x61
.eqv KEY_S 0x73
.eqv KEY_D 0x64

############################ GAME DATA ###############################

# ENTITY INFORMATION
.eqv MAX_OBJECTS 1#6		# The maximum number of objects (platforms/entities) allowed on 
				# the screen at once. (Array size of OBJECT_X arrays)

.align 2
OBJECT_LOCATIONS: .space 64 # Should be default initialized to 0
# Word array representing the (x,y) location of each object on the screen.
# The higher-order 8 bits represent the y-value of the object * width. y-values go from the top 
# of the screen (0) to the bottom of the screen.
# The lower-order 7 bits represent the x-value of the object * unit size. The middle bit is unused.
# x-values go from the left of the screen (0) to the right of the screen.
# The first element is reserved for the player.

.align 1
OBJECT_DETAILS: .space 32
# Object details are represented by a halfwords. Specific bits in the halfword represent specific
# details about the object.
# The first element is reserved for the player.
# 				 object: 15b|14b|13b|...|2b|1b|0b
# bits 0-3 are used to determine object movement direction:
# 	0b = 1 when the player will move in the x-direction this frame.
# 	1b = 0/1 when the player is going to move left/right.
# 	2b = 1 when the player will move in the y-direction this frame.
#  	3b = 0/1 when the player is going to move up/down.
# bits 4-6 are used to specify the type of object that this byte refers to.
# 	000 = Player
#	001 = Platform
#	010 = Fire wall
#	011 = Lava fish
#	100 = Pigeon
# bits 7-14 are details specific to the object that this halfword refers to.
#	PLAYER:
#	 bits 7-8 acts as a regular 2-bit value representing the health that the player 
#	 has remaining.
#	 bits 9-11 act as a regular 3-bit value representing the distance that the player has jumped so far.
#	PLATFORM:
#	 bits 7-9 act as a regular 3-bit value representing the length of the platform.
#	 bits 10-12 acts as a regular 3-bit value representing how much of the platform is currently 
#	 visible on the screen. 
#	FIRE WALL:
#	 bits 7-8 act as a regular 2-bit value representing the height of the wall.
#	LAVA FISH:
#	 bits 7-12 act as the maximum unit height that the fish will leap to. This value is shifted to the left
#	 by 2 to get the y-value in units that the fish will jump.
#	 bits 13-14 act as a regular 2-bit value representing the jump and fall speed of the fish. 
#	PIGEON:
#	 bits 7-9 act as a regular 3-bit value representing the fall speed of the bird. 
# bit 15 is used to specify whether this object is active. If this bit is 0, then there is no object
# currently using this memory location, and it can be replaced. If this bit is 1, then there is an
# object which can't be overwritten until it is marked inactive.

# PLAYER-SPECIFIC INFORMATION
.eqv PLAYER_WIDTH 3 		# Width of the player in units
.eqv PLAYER_HEIGHT 4		# Height of the player in units

.eqv INITIAL_HP 3		# The initial health that the player starts with
.eqv MAX_JUMP_HEIGHT 8		# The maximum height that the player can jump

PLAYER_SPR: .word BLACK, PLAYER_HEAD, BLACK, 
		  PLAYER_BODY, PLAYER_BODY, PLAYER_BODY,
		  BLACK, PLAYER_BODY, BLACK, 
		  BLACK, PLAYER_LEGS, BLACK

# DEBUG OBJECTS 
TEST_SPR: .word WHITE, PLAYER_HEAD, WHITE,
		PLAYER_BODY, PLAYER_BODY, PLAYER_BODY, 
		WHITE, PLAYER_BODY, WHITE, 
		WHITE, PLAYER_LEGS, WHITE

######################################################################

.text
.globl main

########################## MAIN FUNCTION #############################

main:

# REGISTER CONTRACT:
# a0, a1, a2, a3  - arguments to be given to functions
# t4, t5, t6 - intermediate storage for values to be used and discarded
# s0, s1, s2, s3 - variables not preserved across sections
# s6 - OBJECT_LOCATIONS Array
# s7 - OBJECT_DETAILS Array 

main_init:
# Initialization Section
	
	la $s6, OBJECT_LOCATIONS
	la $s7, OBJECT_DETAILS

	# Initialize player location	
	li $t4, 6 # Player's x-position accounting for sprite size (in units, screen goes from 0 - 16)
	sll $t4, $t4, UNIT_S
	sh $t4, 0($s6) # Store x position * unit 
	li $t4, 20 # Player's y-position accounting for sprite size (in units, screen goes from 0 - 32)
	sll $t4, $t4, WIDTH_S
	sh $t4, 2($s6) # Store y position * width
	
	# Initialize player details
	li $t4, 0x8100 # 1 000 000 10 000 0000 initializes active player with 3 health.
	sw $t4, 0($s7)

main_start_loop: 
# Start of the main game loop

main_handle_collisions:
# Handle collision detection to ensure no game objects make invalid movements.

main_handle_input:
# Handle input passed in by the player.
	
# Registers overwritten:
# s0 - Keyboard input

	la $t4, INPUT
	lw $t5, 0($t4) # Check for input
	beqz $t5, main_handle_physics # Skip to physics if no input registered
	lw $s0, 4($t4) # Load input
	
main_input_w:
	bne $s0, KEY_W, main_input_a # Skip if key != 'w'
	lw $t4, 0($s7) # Get player details
	ori $t4, $t4, 0x4 # X XXX XXX XX XXX 01XX Set player to move up.
	sw $t4, 0($s7) # Update player details
	j main_handle_physics
	
main_input_a:
	bne $s0, KEY_A, main_input_s # Skip if key != 'a'
	lw $t4, 0($s7) # Get player details
	ori $t4, $t4, 0x1 # X XXX XXX XX XXX XX01 Set player to move left.
	sw $t4, 0($s7) # Update player details
	j main_handle_physics

main_input_s:
	bne $s0, KEY_S, main_input_d # Skip if key != 's'
	lw $t4, 0($s7) # Get player details
	ori $t4, $t4, 0xC# X XXX XXX XX XXX 11XX Set player to move down.
	sw $t4, 0($s7) # Update player details
	j main_handle_physics

main_input_d:
	bne $s0, KEY_D, main_handle_physics # Skip if key != 'd'
	lw $t4, 0($s7) # Get player details
	ori $t4, $t4, 0x3 # X XXX XXX XX XXX XX11 Set player to move up.
	sw $t4, 0($s7) # Update player details
	
main_handle_physics:
# Handle the movement that occurs in the game world without player input.

# Registers overwritten:
# s0 - Object location address
# s1 - Object details address
# s2 - Loop index
# s3 - Details of current object
	
	move $s0, $s6 # Load initial location address
	move $s1, $s7 # Load initial details address
	li $s2, 0
main_physics_loop:
	beq $s2, MAX_OBJECTS, main_physics_loop_end # loop while s2 < MAX_OBJECTS
	
	# Check if object exists (bit 15 of object details is == 1)
	lh $s3, 0($s1)
	srl $t4, $s3, 31 # Consider only existance bit
	beqz $t4, main_object_exists_end
main_object_exists:
	# TODO: Make sure sprite is cleaned before printing

	# Handle x-movement
	lh $a0, 0($s0)
	andi $a1, $s3, 0x3 # Consider only 0b and 1b in object details
	li $a2, UNIT # Move by one unit
	jal move_object_c
	
	sh $v0, 0($s0) # Update location
	li $t4, 0
	andi $s3, $s3, 0xFFFC # Set x-movement bit and left/right bit to 0
	sh $s3, 0($s1) # Update object details
	
	# Handle y-movement 
	lh $a0, 2($s0)
	andi $a1, $s3, 0xC # Consider only 2b and 3b in object details
	srl $a1, $a1, 2
	li $a2, WIDTH # Move by one unit vertically
	jal move_object_c
	
	sh $v0, 2($s0) # Update location
	li $t4, 0
	andi $s3, $s3, 0xFFF3 # Set y-movement and up/down bit to 0
	sh $s3, 0($s1) # Update object details
	
main_object_exists_end:	

	addi $s0, $s0, 4 # Increment by word
	addi $s1, $s1, 2 # Increment by halfword

	addi $s2, $s2, 1
	j main_physics_loop

main_physics_loop_end:


main_handle_objects:
# Introduce new objects into the game world and remove unneeded ones.

main_handle_drawing:
# Draw and clear sprites from the screen based on states set by previous sections.

	la $a0, TEST_SPR
	li $a1, PLAYER_WIDTH
	li $a2, PLAYER_HEIGHT
	# Store screen address to print to
	lh $t4, 0($s6) # Get player x-val
	lh $t5, 2($s6) # Get player y-val
	add $t4, $t4, $t5 # array index = x + (y * WIDTH)
	add $a3, $gp, $t4 # increment starting screen address by array index. 
	jal print_sprite_c

main_frame_sleep:
# Sleep for a0 milliseconds

	li $v0, 32 
	li $a0, 5
	syscall
	
	j main_start_loop # Jump to beginning of main game loop

main_end:
	li $v0, 10 # Terminate the program gracefully 
	syscall
	
########################### FUNCTIONS ################################
	
print_sprite_c:
# Prints the given sprite into the given array. 
#
# a0 -- sprite memory address starting location
# a1 -- sprite width
# a2 -- sprite length
# a3 -- starting location detailing where to print the top corner of the sprite
# example call:
#	la $a0, PLAYER_SPR
#	li $a1, PLAYER_WIDTH
#	li $a2, PLAYER_HEIGHT
#	lh $t4, 0($s6) # Get player x-val
#	lh $t5, 2($s6) # Get player y-val
#	add $t4, $t4, $t5 # array index = x + (y * WIDTH)
#	add $a3, $gp, $t4 # increment starting screen address by array index. 
#	jal print_sprite_c

# Registers in use:
# t0 - sprite address
# t1 - screen address
# t4 - intermediate storage for temporary values
# t6 - height counter
# t7 - width counter

	move $t0, $a0 # Get the player's sprite address
	move $t1, $a3 # Get marker to the start of the screen
	
	li $t6, 0 # Initialize counter for height of player
pspr_print:	
	bge $t6, $a2, pspr_end
	
	li $t7, 0 # Initialize counter for width of player
pspr_print_segment:
	bge $t7, $a1, pspr_next_row
	 
	lw $t4, 0($t0) # Load colour of sprite
	addi $t0, $t0, UNIT # Advance the sprite pointer
	sw $t4, 0($t1) # Print colour to screen
	addi $t1, $t1, UNIT # Advance the screen pointer 
	
	addi $t7, $t7, 1 # Increment width counter
	j pspr_print_segment
	
pspr_next_row:	
	# Get number of bytes we need to move back to reach left side of sprite
	sll $t4, $a1, UNIT_S # width * unit
	
	addi $t1, $t1, WIDTH # Move to the next row
	sub $t1, $t1, $t4 # Go back to the left side of sprite to draw properly
	
	addi $t6, $t6, 1 # Increment height counter
	j pspr_print	

pspr_end:
	jr $ra
# print_sprite_c

move_object_c:
# Returns what the new location would be of an object that was moved from a given location
# according to the given movement details.
#
# v0 -- The new location details of the object.
# a0 -- 16-bit initial x or y location. 
# a1 -- movement details. This is a 2-bit value, with each bit having a different meaning.
#					1b|0b
#	0b = 1 if there will be movement. If this bit is 0, then the starting location will be returned.
#	1b = 0/1 depending on whether there is positive/negative movement.
# a2 -- scaling amount. Represents how far the object travels in a given direction
#	If this amount = C * UNIT, then the object may move in the x-direction by +/- C units.
#	If this amount = C * WIDTH, then the object may move in the y-direction by +/- C units.

# Registers in use:
# t0 - Amount being moved
# t4 - intermediate storage for movement detail bits
# t5, t6 - intermediate steps in logical expression 

	li $t0, 0 # No movement by default

	# Get whether moving 
	andi $t4, $a1, 0x1 # Consider only bit 0.
	
	beqz $t4, mvob_end
mvob_calculate:
	# Get whether positive or negative movement
	andi $t4, $a1, 0x2 # Consider only bit 1.

	beqz $t4, mvob_negative_movement # if movement bit is 0 => t4 is 0
mvob_positive_movement:
	move $t0, $a2 
	j mvob_end
mvob_negative_movement:
	move $t0, $a2
	not $t0, $t0
	addi $t0, $t0, 1 # negative (Two's complement)
	
mvob_end:
	add $v0, $a0, $t0
	jr $ra
# move_object_c
