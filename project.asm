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
#   calling function, unless expressly stated in function docs.
#####################################################################

.data 

######################### SYSTEM CONSTANTS ##########################

# BITMAP DETAILS
.eqv WIDTH 64		# Width of the bitmap display in units
.eqv HEIGHT 128		# Height of the bitmap display in units
.eqv UNIT 1		# Size of one unit

# COLOURS 
.eqv WHITE 0x00ffffff
.eqv BLACK 0x00000000

.eqv PLAYER_HEAD 0x00ffb100
.eqv PLAYER_BODY 0x00bA6314
.eqv PLAYER_LEGS 0X001439ba

# KEYPRESSES
.eqv KEY_W 0x77
.eqv KEY_A 0x61
.eqv KEY_S 0x73
.eqv KEY_D 0x64

############################ GAME DATA ###############################

# Player Information
.eqv PLAYER_WIDTH 3 		# Width of the player in units
.eqv PLAYER_HEIGHT 4		# Height of the player in units

PLAYER_SPR: .word BLACK, PLAYER_HEAD, BLACK, PLAYER_BODY, PLAYER_BODY, PLAYER_BODY, BLACK, PLAYER_LEGS, BLACK, BLACK, WHITE, BLACK
TEST_SPR: .word WHITE, PLAYER_HEAD, WHITE, PLAYER_BODY, PLAYER_BODY, PLAYER_BODY, WHITE, PLAYER_LEGS, WHITE, WHITE, WHITE, WHITE # TODO: Remove

######################################################################

.text
.globl main

########################## MAIN FUNCTION #############################

main:


end:
	li $v0, 10 # terminate the program gracefully 
	syscall
	
########################### FUNCTIONS ################################
	
print_sprite:
# a0 -- sprite memory address starting location
# a1 -- sprite width
# a2 -- sprite length
# a3 -- starting location to print top corner of the sprite to
# example call:
#	la $a0, PLAYER_SPR
#	li $a1, PLAYER_WIDTH
#	li $a2, PLAYER_HEIGHT
#	add $a3, $gp, $zero
#	jal print_sprite

	add $t0, $a0, $zero # Get the player's sprite address
	add $t1, $a3, $zero # Get marker to the start of the screen
	
	
	li $t6, 0 # Counter for height of player
pspr_print_player:	
	bge $t6, $a2, pspr_end
	
	
	li $t7, 0 # Counter for width of player
pspr_print_segment:
	bge $t7, $a1, pspr_next_row
	 
	lw $t4, 0($t0) # Load colour of sprite
	addi $t0, $t0, 4 # Advance the sprite pointer
	sw $t4, 0($t1) # Print colour to screen
	addi $t1, $t1, 4 # Advance the screen pointer 
	
	addi $t7, $t7, 1
	j pspr_print_segment
	
pspr_next_row:
	addi $t1, $t1, 64
	subi $t1, $t1, 12 # Go back 3 units to left side of sprite
	
	addi $t6, $t6, 1 # Increment counter
	j pspr_print_player	

pspr_end:
	jr $ra
	

