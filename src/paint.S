.globl paint

#include "ant_constants.h"

#define MAX_COLOURS 6
#define N_ORIENTATIONS 4
#define X 0
#define Y 1

# int rules_map[MAX_COLOURS] size, in bytes
#define SZ_RULESMAP (4 * MAX_COLOURS)
# orientation_t orientation[N_ORIENTATIONS] size, in bytes
#define SZ_ORIENTATION (4 * N_ORIENTATIONS)
# int increments[N_ORIENTATIONS][2] size, in bytes
#define SZ_INCREMENTS (4 * 2 * N_ORIENTATIONS)
#define SZ_FP 4
#define SZ_GP 4

# Stack size
#define SS (SZ_RULESMAP + SZ_ORIENTATION + SZ_INCREMENTS + SZ_FP + SZ_GP)

# Offset to each argument in the ABA
#define O_ARG0(sp) (SS + 0)(sp)
#define O_ARG1(sp) (SS + 4)(sp)
#define O_ARG2(sp) (SS + 8)(sp)
#define O_ARG3(sp) (SS + 12)(sp)
#define O_ARG4(sp) (SS + 16)(sp)

# Offset to fp and gp
#define O_FP (SS-4)(sp)
#define O_GP (SS-8)(sp)
 
# Offset to the rules map (index, reg)
#define O_RULESMAP_START    (SS - SZ_RULESMAP)
#define O_RULESMAP(idx, sp) (O_RULES_MAP + 4 * idx)(sp)

# Offset to the orientations array (index, reg)
#define O_ORIENTATION_START    (O_RULESMAP_START - SZ_ORIENTATION)
#define O_ORIENTATION(idx, sp) (O_ORIENTATION_START + 4 * idx)(sp)

# Offset to the increments array (offset, coordinate, reg)
#define O_INCREMENTS_START     (O_ORIENTATION_START - SZ_INCREMENTS)
#define O_INCREMENTS(o, c, sp) (O_INCREMENTS_START + (o * 8) + (4 * c))(sp)

# Offset to ant_t structure
#define O_X(reg)  (0)(reg)
#define O_Y(reg)  (4)(reg)
#define O_O(reg)  (8)(reg)

# Offset to square_grid_t structure
#define O_WIDTH(reg)  (0)(reg)
#define O_HEIGHT(reg) (4)(reg)
#define O_GRID(reg)   (8)(reg)

# Offset to the length of an unsigned int vector.
#define O_UIVLEN(sp) -4(sp)

# #############################################################################
# void*
# paint(void *ant, void *grid, void *palette, void *rules, uint32_t iterations)
# 
# Assembly implementation of the paint function.
#
#
# Stack usage:
#  [SS - O_RULES_MAP]   => int rules_map[MAX_COLOURS]
#  [SS - O_ORIENTATION] => orientation_t orientation[N_ORIENTATIONS]
#  [SS - O_INCREMENTS]  => int increments[N_ORIENTATIONS][2]
#  [SS - O_GP]
#  [SS - O_FP] 
#
# Register usage:
#  -- Arguments --
# $a0: ant_t* ant
# $a1: square_grid_t* grid
# $a2: uintvector_t* palette
# $a3: uintvector_t* rules
# $v0: uint32_t iterations
#
#  -- Locals (function scope) --
# $v1: int current_orientation_index
# $t0: orientation_t orientation[N_ORIENTATIONS]
# $t1: int increments[N_ORIENTATIONS][2]
# $t2: int rules_map[MAX_COLOURS]
#
#  -- Locals (rules_loop scope) --
# $t3: uint32_t index
# auxiliars: $t4, $t5, $t6, $t7
#
#  -- Locals (main_loop scope) --
# $t3: uint32_t index
# $t4: colour_t* current_cell
# $t5: uint32_t current_turn
# $t6: colour_t next_colour
# auxiliars: $t7, $t8, $t9
#
# #############################################################################
paint:
        addiu   $sp,$sp,-SS             # Create the stack frame
        
        # Set up ABA and load fifth argument into registers
        sw      $a0,O_ARG0($sp)         # Store $a0 in the ABA
        sw      $a1,O_ARG1($sp)         # Store $a1 in the ABA
        sw      $a2,O_ARG2($sp)         # Store $a2 in the ABA
        sw      $a3,O_ARG3($sp)         # Store $a3 in the ABA
        lw      $v0,O_ARG4($sp)         # Load fifth argument (iterations)
	
	# Store fp and gp
	sw	$fp,O_FP($sp)		# Store fp in the ABA
	sw	$gp,O_GP($sp)		# Store gp in the ABA
        
        # Load locals from function scope into registers
        add     $v1,$zero,0                   # current_orientation = 0
        add     $t0,$sp,O_ORIENTATION_START   # Load orientation address
        add     $t1,$sp,O_INCREMENTS_START    # Load increments address
        add     $t2,$sp,O_RULESMAP_START      # Load rules map address

        # Build orientation array
        add     $t7,$zero,ON                # Copy ON constant to $t7
        sw      $t7,O_ORIENTATION(0,$sp)    # Store $t7 in orientation[0]
        add     $t7,$zero,OE
        sw      $t7,O_ORIENTATION(1,$sp)
        add     $t7,$zero,OS
        sw      $t7,O_ORIENTATION(2,$sp)
        add     $t7,$zero,OW
        sw      $t7,O_ORIENTATION(3,$sp)

        # Build increments array
        lw      $t7,O_WIDTH($a1)             # Load width into $t7
        addiu   $t7,$t7,-1                   # $t7 = width - 1
        lw      $t8,O_HEIGHT($a1)            # Load height into $t8            
        addiu   $t8,$t8,-1                   # $t8 = height - 1
        add     $t9,$zero,1                  # $t9 = 1
        sw      $zero,O_INCREMENTS(ON,X,$sp) # { {0,
        sw      $t8,  O_INCREMENTS(ON,Y,$sp) #    height - 1},
        sw      $t9,  O_INCREMENTS(OE,X,$sp) #   {1,
        sw      $zero,O_INCREMENTS(OE,Y,$sp) #    0},
        sw      $zero,O_INCREMENTS(OS,X,$sp) #   {0,
        sw      $t9,  O_INCREMENTS(OS,Y,$sp) #    1},
        sw      $t7,  O_INCREMENTS(OW,X,$sp) #   {width - 1,
        sw      $zero,O_INCREMENTS(OW,Y,$sp) #    0} }

        # Build rules map array
        add     $t3,$zero,0             # index = 0
        lw      $t4,O_UIVLEN($a2)       # Load palette size into $t4
    rules_loop:
        beq     $t3,$t4,rules_loop_end  # while ($t3 != $t4) {
        add     $t5,$t3,0               #   $t5 = index
        sll     $t5,2                   #   $t5 = index * 4
        add     $t6,$a2,$t5             #   $t6 = (index * 4) + palette
        add     $t7,$a3,$t5             #   $t7 = (index * 4) + rules
        lw      $t6,0($t6)              #   $t6 = palette[index]
        lw      $t7,0($t7)              #   $t7 = rules[index]
        sll     $t6,2                   #   $t6 = palette[index] * 4
        add     $t6,$t6,$t2             #   $t6 = rules_map[palette[index]]
        sw      $t7,0($t6)              #   rules_map[palette[index]] = rules[index]
        addiu   $t3,$t3,1               #   $t3++
        b       rules_loop              # }
    rules_loop_end:                         
        addiu   $t3,$zero,0             # index = 0
    main_loop:
        beq     $t3,$v0,main_loop_end   # while (index != iterations) {

        # Load current grid position into $t4
        lw      $t4,O_GRID($a1)         #   $t4 = sgrid->grid
        lw      $t7,O_Y($a0)            #   $t7 = sant->y
        sll     $t7,$t7,2               #   $t7 = sant->y * 4
        add     $t4,$t4,$t7             #   $t4 = sgrid->grid + sant->y
        lw      $t4,0($t4)              #   $t4 = sgrid->grid[sant->y]
        lw      $t7,O_X($a0)            #   $t7 = sant->x
        sll     $t7,$t7,2               #   $t7 = sant->x * 4
        add     $t4,$t4,$t7             #   $t4 = sgrid->grid[sant->y] + sant->x
        
        # Load current turn direction into $t5
        lw      $t5,0($t4)              #   $t5 = sgrid->grid[sant->y][sant->x]
        sll     $t5,$t5,2               #   $t5 = current_colour * 4
        add     $t5,$t5,$t2             #   $t5 = rules_map + current_colour
        lw      $t5,0($t5)              #   $t5 = rules_map[current_colour]

        # Load next colour into $t6
        lw      $t9,O_UIVLEN($a2)
        addiu   $t6,$t3,1               #   $t6 = index + 1
        rem     $t6,$t6,$t9             #   $t6 = (index + 1) % palette_size
        sll     $t6,$t6,2               #   $t6 = ((index + 1) % palette_size) * 4
        addu    $t6,$t6,$a2             #   $t6 = colours + ((index + 1) % palette_size)
        lw      $t6,0($t6)              #   $t6 = colours[(index + 1) % palette_size]

        # Change current orientation
        addu    $v1,$v1,$t5             #   $v1 = current_orientation + current_turn
        addiu   $t7,$zero,N_ORIENTATIONS #  $t7 = N_ORIENTATIONS
        rem     $v1,$v1,$t7             #   $v1 = (current_orientation + current_turn) % N_ORIENTATIONS
        
        # Store current orientaion in sant->o
        sll     $t7,$v1,2               #   $t7 = current_orientation * 4
        add     $t9,$t7,$t0             #   $t9 = orientation + current_orientation
        lw      $t9,0($t9)              #   $t9 = orientation[current_orientation]
        sw      $t9,O_O($a0)            #   sant->o = orientation[current_orientation]

        # Paint the current cell with next_colour
        sw      $t6,0($t4)

        # Increment current position according to orientation
        sll     $t7,$v1,4               #   $t7 = current_orientation * sizeof({0, 0})
        add     $t7,$t7,$t0             #   $t7 = increments + current_orientation
        lw      $t8,0($t7)              #   $t8 = increments[current_orientation][X]
        lw      $t9,4($t7)              #   $t9 = increments[current_orientation][Y]
        
        lw      $t7,O_X($a0)            #   $t7 = sant->x
        add     $t8,$t7,$t8             #   $t8 = sant->x + increments[current_orientation][X]
        lw      $t7,O_WIDTH($a1)        #   $t7 = sgrid->width
        rem     $t8,$t8,$t7             #   $t8 = (sant->x + increments[current_orientation][X]) % sgrid->width
        sw      $t8,O_X($a0)            #   sant->x = $t8

        lw      $t7,O_Y($a0)            #   $t7 = sant->y
        add     $t8,$t7,$t8             #   $t8 = sant->y + increments[current_orientation][Y]
        lw      $t7,O_HEIGHT($a1)       #   $t7 = sgrid->height
        rem     $t8,$t8,$t7             #   $t8 = (sant->y + increments[current_orientation][Y]) % sgrid->height
        sw      $t8,O_Y($a0)            #   sant->y = $t8

        # Increment iteration counter and loop
        addiu   $t3,$t3,1               #   index++
        b main_loop
    main_loop_end:
        addiu   $sp,$sp,SS              #   Destroy the stack frame
        addiu   $v0,$a1,0               #   return grid
        jr      $ra                     #
