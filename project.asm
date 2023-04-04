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
.eqv WIDTH_U 16		# Width of the bitmap display in units
.eqv WIDTH_S 6		# The shift equivalent to scaling by width (val * WIDTH == val << WIDTH_S)
.eqv HEIGHT 128		# Height of the bitmap display in pixels
.eqv HEIGHT_U 32	# Height of the bitmap display in pixels
.eqv UNIT 4		# Size of one unit in pixels
.eqv UNIT_S 2		# The shift equivalent to scaling by a unit (val * UNIT == val << UNIT_S)
.eqv FRAME_DELAY 70

# COLOURS 
.eqv WHITE 		0x00ffffff
.eqv BLACK		0x00000000

.eqv PLAYER_HEAD 	0x00ffb100
.eqv PLAYER_BODY 	0x00bA6314
.eqv PLAYER_LEGS 	0x00146aba

.eqv BLOCKABLE    	0x009fb8cf  	# This colour represents objects that the player 
					# can collide with safely, and blocks the player's path.
.eqv DAMAGING		0x00a60828	# This colour represents objects that damage the player
				    	# upon collision.
.eqv DEADLY		0x00e6330b  	# This colour represents objects that immediately kill the 
					# player upon collision.

# KEYPRESSES
.eqv INPUT 0xffff0000
.eqv KEY_W 0x77
.eqv KEY_A 0x61
.eqv KEY_S 0x73
.eqv KEY_D 0x64

############################ GAME DATA ###############################

# OBJECT INFORMATION
.eqv MAX_OBJECTS 2		# The maximum number of objects (platforms/entities) allowed on 
				# the screen at once. (Array size of OBJECT_X arrays)

OBJECT_LOCATIONS: .word 0:MAX_OBJECTS
# Word array representing the (x,y) location of each object on the screen.
# The higher-order 8 bits represent the y-value of the object * width. y-values go from the top 
# of the screen (0) to the bottom of the screen.
# The lower-order 7 bits represent the x-value of the object * unit size. The middle bit is unused.
# x-values go from the left of the screen (0) to the right of the screen.
# The first element is reserved for the player.

CLEAN_LOCATIONS: .word 0xFFFFFFFF:MAX_OBJECTS
# Word array representing a pointer to the bitmap screen where the corresponding object in the OBJECT_LOCATIONS
# array was. These locations need to be erased when drawing movement, so that object remnants don't stick around.
# If there is no past location initialized in an element, the value of the element is set to all 1s.

OBJECT_DETAILS: .half 0:MAX_OBJECTS
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
#	 bits 9-12 act as a regular 4-bit value representing the distance that the player has jumped so far.
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

# PLAYER INFORMATION

.eqv PLAYER_WIDTH 3 		# Width of the player in units
.eqv PLAYER_HEIGHT 4		# Height of the player in units

.eqv INITIAL_HP 3		# The initial health that the player starts with
.eqv MAX_JUMP_HEIGHT 10		# The maximum height that the player can jump

# SPRITES

CLEAN_SPR: .word BLACK:32 	# A large sprite made entirely of black so that the print sprite function can be used 
				# with it and varying widths/heights to clean other sprites as they move
				
BORDER_SPR: .word BLOCKABLE:HEIGHT	# The blocking border wall around the screen to prevent crossing past the sides of the screen

LAVA_SPR: .word DEADLY:WIDTH

PLAYER_SPR: .word BLACK, PLAYER_HEAD, BLACK, 
		  PLAYER_BODY, PLAYER_BODY, PLAYER_BODY,
		  BLACK, PLAYER_BODY, BLACK, 
		  BLACK, PLAYER_LEGS, BLACK

PLATFORM_SPR: .word BLOCKABLE:8		

# DEBUG
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
# s0, s1, s2, s3, s4 - variables not preserved across sections
# s5 - CLEAN_LOCATIONS Array
# s6 - OBJECT_LOCATIONS Array
# s7 - OBJECT_DETAILS Array

main_init:
# Initialization Section
	
	la $s5, CLEAN_LOCATIONS
	la $s6, OBJECT_LOCATIONS
	la $s7, OBJECT_DETAILS 

	# Draw borders
	la $a0, LAVA_SPR
	li $a1, 16
	li $a2, 1
	li $a3, 0x100087C0 # Bottom row of screen
	jal print_sprite_c
	subi $a3, $a3, WIDTH # 2nd last row
	jal print_sprite_c
	subi $a3, $a3, WIDTH # 3rd last row
	jal print_sprite_c

	la $a0, BORDER_SPR
	li $a1, 1
	li $a2, HEIGHT
	addi $a3, $gp, 0 # left side
	jal print_sprite_c
	
	addi $a3, $gp, WIDTH
	subi $a3, $a3, 4 # Right side
	jal print_sprite_c

	# Initialize player location	
	li $t4, 6 # Player's x-position accounting for sprite size (in units, screen goes from 0 - WIDTH_U)
	sll $t4, $t4, UNIT_S
	sh $t4, 0($s6) # Store x position * unit 
	li $t4, 20 # Player's y-position accounting for sprite size (in units, screen goes from 0 - HEIGHT_U)
	sll $t4, $t4, WIDTH_S
	sh $t4, 2($s6) # Store y position * width
	
	# Initialize player details
	li $t4, 0x8100 # 1 000 000 10 000 0000 initializes active player with 3 health.
	sh $t4, 0($s7)
	
	# Initialize initial platform location
	li $t4, 5 # Platform's x-position accounting for sprite size (in units, screen goes from 0 - WIDTH_U)
	sll $t4, $t4, UNIT_S
	sh $t4, 4($s6) # Store x position * unit 
	li $t4, 24 # platform's y-position accounting for sprite size (in units, screen goes from 0 - HEIGHT_U)
	sll $t4, $t4, WIDTH_S
	sh $t4, 6($s6) # Store y
	
	# Initialize platform details
	li $t4, 0x8E90 # 1 00 011 011 001 0000 initializes a starting platform with length of 5
	sh $t4, 2($s7) 	

main_start_loop: 
# Start of the main game loop

main_handle_drawing:
# Draw and clear sprites from the screen based on states set by previous sections.

# Registers overwritten:
# s0 - Object location address incremented by loop
# s1 - Object details address incremented by loop
# s2 - Loop index
# s3 - Object details
# s4 - Clean location address incremented by loop

	move $s0, $s6 # Load initial location address
	move $s1, $s7 # Load initial details address
	move $s4, $s5 # Load initial cleaning address
	li $s2, 0 
main_drawing_loop:
	beq $s2, MAX_OBJECTS, main_handle_drawing_end # loop while s2 < MAX_OBJECTS
	
	# Check object existance before printing.
	lh $s3, 0($s1) # Load object details
	andi $t5, $s3, 0x8000 # Consider only bit 15
	beqz $t5, main_drawing_loop_end # Skip if existence bit == 0
	
	# Check if cleaning needed
	lw $t4, 0($s4)
	beq $t4, 0xFFFFFFFF, main_print_object # Skip if cleaning location is all ones
main_clean_object:
	# Load sprite for object
	move $a3, $s3 # Load object details
	jal get_object_spr
	
	la $a0, CLEAN_SPR
	lw $a3, 0($s4) # Location to clean	
	jal print_sprite_c
	
	# Empty cleaning location
	li $t4, 0xFFFFFFFF
	sw $t4, 0($s4)

main_print_object:
	# Load sprite for object
	move $a3, $s3 # Load object details
	jal get_object_spr

	# Load current screen address of object
	lh $t4, 0($s0) # Get object x-val
	lh $t5, 2($s0) # Get object y-val
	add $t4, $t4, $t5 # array index = x + (y * WIDTH)
	add $a3, $gp, $t4 # Set printing address
	jal print_sprite_c
		
main_drawing_loop_end:
	addi $s0, $s0, 4 # Increment by word
	addi $s1, $s1, 2 # Increment by halfword
	addi $s4, $s4, 4 # Increment by word
	addi $s2, $s2, 1
	j main_drawing_loop

main_handle_drawing_end:

main_handle_input:
# Handle input passed in by the player.
	
# Registers overwritten:
# s0 - Keyboard input

	la $t4, INPUT
	lw $t5, 0($t4) # Check for input
	beqz $t5, main_handle_input_end # Skip if no input registered
	lw $s0, 4($t4) # Load input
	
main_input_w:
	bne $s0, KEY_W, main_input_a # Skip if key != 'w'
	lw $t4, 0($s7) # Get player details
	
	srl $t5, $t4, 9 
	andi $t5, $t5, 0xF # Consider bits 9-12
	bnez $t5, main_input_a 	# Only jump if currently on in the air (bits 9-12 are 0)
	
	ori $t4, $t4, 0x200 # Set 9b = 1 => 12b|11b|10b|9b| = 0001 as others are already 0.

	sw $t4, 0($s7) # Update player details
	j main_handle_input_end
	
main_input_a:
	bne $s0, KEY_A, main_input_s # Skip if key != 'a'
	lw $t4, 0($s7) # Get player details
	ori $t4, $t4, 0x1 # X XX XXXX XX XXX XX01 Set player to move left.
	sw $t4, 0($s7) # Update player details
	j main_handle_input_end

main_input_s:
	bne $s0, KEY_S, main_input_d # Skip if key != 's'
	lw $t4, 0($s7) # Get player details
	ori $t4, $t4, 0xF00 # X XX 1111 XX XXX XXXX Set player at max jump, causing them to fall.
	sw $t4, 0($s7) # Update player details
	j main_handle_input_end

main_input_d:
	bne $s0, KEY_D, main_handle_input_end # Skip if key != 'd'
	lw $t4, 0($s7) # Get player details
	ori $t4, $t4, 0x3 # X XX XXXX XX XXX XX11 Set player to move up.
	sw $t4, 0($s7) # Update player details
main_handle_input_end:
	
main_handle_physics:
# Handle the physics of the game.

# Registers overwritten:
# s0 - Object location address incremented by loop
# s1 - Object details address incremented by loop
# s2 - Loop index
# s3 - Details of current object
# s4 - Screen location of current object
	
	move $s0, $s6 # Load initial location address
	move $s1, $s7 # Load initial details address
	li $s2, 0
main_physics_loop:
	beq $s2, MAX_OBJECTS, main_handle_physics_end # loop while s2 < MAX_OBJECTS
	
	# Store current screen address of object
	lh $t4, 0($s0) # Get object x-val
	lh $t5, 2($s0) # Get object y-val
	add $t4, $t4, $t5 # array index = x + (y * WIDTH)
	add $s4, $gp, $t4 # increment starting screen address by array index. 

	# We don't need to check object existance, since it is checked when printing.	
	lh $s3, 0($s1) # Load object details

main_player_jump_physics:
	srl $t4, $s3, 4 
	andi $t4, $t4, 0x7 # Consider only bits 4-6
	bnez $t4, main_physics_loop_end # Ignore section if object isn't a player

	# Set up and down movement based on what state of jump the player is on
	srl $t4, $s3, 9 
	andi $t4, $t4, 0xF # Consider bits 9-12 (jump status)
	
	bge $t4, MAX_JUMP_HEIGHT, main_player_descending # If jump distance >= MAX_JUMP_HEIGHT -> Move down
	bgtz $t4, main_player_ascending # If 1 < jump distance < MAX_JUMP_HEIGHT -> Move up
	ori $s3, $s3, 0xE00  # If jump distance is 0, default to moving down
	j main_player_descending
	
main_player_ascending:
	ori $s3, $s3, 0x4 # X XX XXXX XX XXX 01XX Set player to move up.
	addi $t4, $t4, 1 # Increase jump height
	sll $t4, $t4, 9 # Move bits to where they should be
	andi $s3, $s3, 0xE1FF
	or $s3, $s3, $t4 # Set updated jump height
	j main_update_directions
	
main_player_descending:
	ori $s3, $s3, 0xC # X XXX XXX XX XXX 11XX Set player to move down.
	
main_update_directions:
	sh $s3, 0($s1)
	
main_physics_loop_end:

	addi $s0, $s0, 4 # Increment by word
	addi $s1, $s1, 2 # Increment by halfword

	addi $s2, $s2, 1
	j main_physics_loop

main_handle_physics_end:
	
main_handle_collisions:
# Handle collision detection to ensure no game objects make invalid movements.

# Registers overwritten:
# s0 - Object location address incremented by loop
# s1 - Object details address incremented by loop
# s2 - Loop index
# s3 - Details of current object
# s4 - Screen location of current object


	# Collisions need to be handled differently for different objects.
	# The player should not be able to traverse past BLOCKABLE objects.
	# Other objects should be deleted upon completely crossing the border, but ignore other
	# blockable objects. Since  these objects are multi-unit wide, they need to be set in a way 
	# that the units outside of screen borders should not be printed. This needs to be handled by
	# this section setting their widths/heights to a smaller amount to prevent crossing borders.
	# We can handle collisions no matter the existance of the object, since it doesn't affect any outer variables

	move $s0, $s6 # Load initial location address
	move $s1, $s7 # Load initial details address
	li $s2, 0
main_collisions_loop:
	beq $s2, MAX_OBJECTS, main_handle_collisions_end # loop while s2 < MAX_OBJECTS
	
	# Store current screen address of object
	lh $t4, 0($s0) # Get object x-val
	lh $t5, 2($s0) # Get object y-val
	add $t4, $t4, $t5 # array index = x + (y * WIDTH)
	add $s4, $gp, $t4 # increment starting screen address by array index. 

	# We don't need to check object existance, since it is checked when printing.	
	lh $s3, 0($s1) # Load object details
	
	# Get which object is being asked for
	srl $t4, $s3, 4
	andi $t4, $t4, 0x7 # Only consider bits 4-6 to get type of object
	
	beq $t4, 0, main_collision_player
	beq $t4, 1, main_collision_platform
	beq $t4, 2, main_collision_firewall
	beq $t4, 3, main_collision_fish
	beq $t4, 4, main_collision_pigeon
	
main_collision_player:
main_player_on_platform:
	# Check for a platform under the player's feet.
	# Do this by moving down 4 units and right 1 unit from the player's screen address
	li $t4, 1
	sll $t4, $t4, UNIT_S
	add $t5, $s4, $t4 # Current object location + 1 right
	li $t4, 4
	sll $t4, $t4, WIDTH_S
	add $t5, $t5, $t4 # Current object location + 4 down

	lw $t5, 0($t5) # Get colour at unit under player's feet
	bne $t5, BLOCKABLE, main_player_at_right_wall # Skip if object under player isn't a platform
	
	# Stop player trying to move down on platform
	srl $t4, $s3, 3 
	andi $t4, $t4, 0x1 # Consider only up/down bit
	beqz $t4, main_player_at_right_wall # Player not moving down
	
main_player_moving_down:
	andi $s3, $s3, 0xE1FF # Set player's jump time to 0
	andi $s3, $s3, 0xFFF3 # Prevent player from moving downwards

main_player_at_right_wall:
	# Check for wall on right of player
	# Do this by moving down 1 unit and right 3 units from the player's screen address
	li $t4, 3
	sll $t4, $t4, UNIT_S
	add $t5, $s4, $t4 # Current object location + 3 right
	li $t4, 1
	sll $t4, $t4, WIDTH_S
	add $t5, $t5, $t4 # Current object location + 1 down

	lw $t5, 0($t5) # Get colour at unit at right of player
	bne $t5, BLOCKABLE, main_player_at_left_wall # Skip if object isn't at a wall
	
	srl $t4, $s3, 1
	andi $t4, $t4, 0x1 # Consider only left/right bit
	beqz $t4, main_player_at_left_wall # Player not moving right
	
main_player_moving_right:
	andi $s3, $s3, 0xFFFC # Prevent player from moving right

main_player_at_left_wall:
	# Check for wall on left of player
	# Do this by moving down 1 unit and left one unit from the player's screen address
	li $t4, 1
	sll $t4, $t4, UNIT_S # 1 unit left
	sub $t5, $s4, $t4 # Current object location + 1 left
	li $t4, 1
	sll $t4, $t4, WIDTH_S # 1 unit down
	add $t5, $t5, $t4 # Current object location + 4 down

	lw $t5, 0($t5) # Get colour at unit left of player
	bne $t5, BLOCKABLE, main_player_save_collision # Skip if object isn't at a wall
	
	srl $t4, $s3, 1
	andi $t4, $t4, 0x1 # Consider only left/right bit
	beq $t4, 0x1, main_player_save_collision # Player not moving left

main_player_moving_left:
	andi $s3, $s3, 0xFFFC # Prevent player from moving left

main_player_save_collision:
	sh $s3, 0($s1) # Store updated movement
	j main_collisions_loop_end

main_collision_platform:
main_collision_firewall:
main_collision_fish:
main_collision_pigeon:

main_collisions_loop_end:

	addi $s0, $s0, 4 # Increment by word
	addi $s1, $s1, 2 # Increment by halfword

	addi $s2, $s2, 1
	j main_collisions_loop
	
main_handle_collisions_end:

main_handle_movement:
# Handle the movement of every object based on their details.

# Registers overwritten:
# s0 - Object location address incremented by loop
# s1 - Object details address incremented by loop
# s2 - Loop index
# s3 - Details of current object
# s4 - Screen location of current object
	
	move $s0, $s6 # Load initial location address
	move $s1, $s7 # Load initial details address
	li $s2, 0
main_movement_loop:
	beq $s2, MAX_OBJECTS, main_handle_movement_end # loop while s2 < MAX_OBJECTS
	
	# Store current screen address of object
	lh $t4, 0($s0) # Get object x-val
	lh $t5, 2($s0) # Get object y-val
	add $t4, $t4, $t5 # array index = x + (y * WIDTH)
	add $s4, $gp, $t4 # increment starting screen address by array index. 

	# We don't need to check object existance, since it is checked when printing.	
	lh $s3, 0($s1) # Load object details

main_handle_x_movement:
	lh $a0, 0($s0)
	andi $a1, $s3, 0x3 # Consider only 0b and 1b in object details
	li $a2, UNIT # Move by one unit
	jal move_object_c

	beq $v0, $a0, main_handle_y_movement # Decrease jitter by not updating the object unless it has moved

	# Set current location of object to be cleaned if there was x movement
	sll $t4, $s2, 2 # Get index of element in object arrays
	add $t4, $s5, $t4 # address of element in CLEAN_LOCATIONS
	sw $s4, 0($t4) # CLEAN_LOCATIONS[s2] = current_location 
	
	sh $v0, 0($s0) # Update location
	li $t4, 0
	andi $s3, $s3, 0xFFFC # Set x-movement bit and left/right bit to 0
	sh $s3, 0($s1) # Update object details
	
main_handle_y_movement:
	lh $a0, 2($s0)
	andi $a1, $s3, 0xC # Consider only 2b and 3b in object details
	srl $a1, $a1, 2
	li $a2, WIDTH # Move by one unit vertically
	jal move_object_c
	
	beq $v0, $a0, main_movement_loop_end # Decrease jitter by not updating the object unless it has moved
	
	# Set current location of object to be cleaned if there was y movement
	sll $t4, $s2, 2 # Get index of element in object arrays
	add $t4, $s5, $t4 # address of element in CLEAN_LOCATIONS
	sw $s4, 0($t4) # CLEAN_LOCATIONS[s2] = current_location 

	sh $v0, 2($s0) # Update location
	li $t4, 0
	andi $s3, $s3, 0xFFF3 # Set y-movement and up/down bit to 0
	sh $s3, 0($s1) # Update object details
	
main_movement_loop_end:

	addi $s0, $s0, 4 # Increment by word
	addi $s1, $s1, 2 # Increment by halfword

	addi $s2, $s2, 1
	j main_movement_loop

main_handle_movement_end:

main_handle_objects:
# Introduce new objects into the game world and remove unneeded ones.

main_frame_sleep:
# Sleep for a0 milliseconds

	li $v0, 32 
	li $a0, FRAME_DELAY
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

get_object_spr:
# Gets the sprite, width, and height of an object based on a given object details halfword.
# These values are stored in argument parameters.
#
# a0 -- Will contain the initial memory address of the sprite.
# a1 -- Will contain the width of the sprite.
# a2 -- Will contain the height of the sprite.
# a3 -- The object details value used to choose which sprite details to get.

# Registers in use:
# t4 - Intermediate values between calculations.

	# Get which object is being asked for
	srl $t4, $a3, 4
	andi $t4, $t4, 0x7 # Only consider bits 4-6 to get which object to print
	
	beq $t4, 0, gobs_player_spr
	beq $t4, 1, gobs_platform_spr
	beq $t4, 2, gobs_firewall_spr
	beq $t4, 3, gobs_fish_spr
	beq $t4, 4, gobs_pigeon_spr

gobs_default_spr: # Use default test sprite if t4 fails to resolve to a valid object
	la $a0, TEST_SPR
	li $a1, PLAYER_WIDTH
	li $a2, PLAYER_HEIGHT
	jr $ra	

gobs_player_spr:
	la $a0, PLAYER_SPR
	li $a1, PLAYER_WIDTH
	li $a2, PLAYER_HEIGHT
	jr $ra
	
gobs_platform_spr:
	la $a0, PLATFORM_SPR
	srl $a1, $a3, 7 # Make bits 7-9 the smallest bits
	andi $a1, $a1, 0x7 # Consider only bits 7-9 as a three bit value for platform width
	li $a2, 1
	jr $ra

gobs_firewall_spr:
	la $a0, TEST_SPR
	li $a1, PLAYER_WIDTH
	li $a2, PLAYER_HEIGHT
	jr $ra	# Unimplemented

gobs_fish_spr:
	la $a0, TEST_SPR
	li $a1, PLAYER_WIDTH
	li $a2, PLAYER_HEIGHT
	jr $ra	# Unimplemented
		
gobs_pigeon_spr:
	la $a0, TEST_SPR
	li $a1, PLAYER_WIDTH
	li $a2, PLAYER_HEIGHT
	jr $ra	# Unimplemented
	
