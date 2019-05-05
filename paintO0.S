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

# Stack size
#define SS (SZ_RULESMAP + SZ_ORIENTATION + SZ_INCREMENTS)

# Offset to each argument in the ABA
#define O_ARG0(sp) (SS + 0)(sp)
#define O_ARG1(sp) (SS + 4)(sp)
#define O_ARG2(sp) (SS + 8)(sp)
#define O_ARG3(sp) (SS + 12)(sp)
#define O_ARG4(sp) (SS + 16)(sp)
 
# Offset to the rules map (index, reg)
#define O_RULESMAP(idx, sp) (SS - SZ_RULESMAP + 4 * idx)(sp)

# Offset to the orientations array (index, reg)
#define O_ORIENTATION(idx, sp) (O_RULESMAP - SZ_ORIENTATION + 4 * idx)(sp)

# Offset to the increments array (offset, coordinate, reg)
#define O_INCREMENTS(o, c, sp) (O_ORIENTATION - SZ_INCREMENTS + (o * 8) + (4 * c))(sp)

# Offset to ant_t structure
#define O_X(reg)   (0)(reg)
#define O_Y(reg)  (-4)(reg)
#define O_O(reg)  (-8)(reg)

# Offset to square_grid_t structure
#define O_WIDTH(reg)   (0)(reg)
#define O_HEIGHT(reg) (-4)(reg)
#define O_GRID(reg)   (-8)(reg)

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
# $t4: colour_t current_colour
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
		    
            # Load locals from function scope into registers
            add     $v1,$zero,0             # current_orientation = 0
            add     $t0,$sp,O_ORIENTATION   # Load orientation address
            add     $t1,$sp,O_INCREMENTS    # Load increments address
            add     $t2,$sp,O_RULESMAP      # Load rules map address

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
            addiu   $t9,$t4,0               # Palette size is in $t4 (line 130), move to $t9
            addiu   $t3,$zero,0             # index = 0
            beq     $t3,$v0,main_loop_end   # while (index != iterations) {
            
            # Load current_colour into $t4
            lw      $t4,O_GRID($a1)         #   $t4 = sgrid->grid
            lw      $t7,O_Y($a0)            #   $t7 = sant->y
            sll     $t7,$t7,2               #   $t7 = sant->y * 4
            addiu   $t4,$t7,0               #   $t4 = sgrid->grid + sant->y
            lw      $t4,0($t4)              #   $t4 = sgrid->grid[sant->y]
            lw      $t7,O_X($a0)            #   $t7 = sant->x
            sll     $t7,$t7,2               #   $t7 = sant->x * 4
            addiu   $t4,$t7,0               #   $t4 = sgrid->grid[sant->y] + sant->x
            lw      $t4,0($t4)              #   $t4 = sgrid->grid[sant->y][sant->x]

            # Load current turn direction into $t5
            sll     $t5,$t4,2               #   $t5 = current_colour * 4
            addiu   $t5,$t2,0               #   $t5 = rules_map + current_colour
            lw      $t5,0($t5)              #   $t5 = rules_map[current_colour]

            # Load next colour into $t6
            addiu   $t6,$t3,1               #   $t6 = index + 1
            rem     $t6,$t6,$t9             #   $t6 = (index + 1) % palette_size
            sll     $t6,$t6,2               #   $t6 = ((index + 1) % palette_size) * 4
            addiu   $t6,$t6,$a2             #   $t6 = colours + ((index + 1) % palette_size)
            lw      $t6,0($t6)              #   $t6 = colours[(index + 1) % palette_size]

            # Update current orientation in $v1
            addu    $v1,$v1,$t5             #   $v1 = current_orientation + current_turn
            addiu   $t7,$zero,N_ORIENTATIONS #  $t7 = N_ORIENTATIONS
            rem     $v1,$v1,$t7             #   $v1 = (current_orientation + current_turn) % N_ORIENTATIONS
            
            # Store current orientaion in sant->o
            sll     $t7,$v1,2               #   $t7 = current_orientation * 4
            
            # ---- completar aca ----



    	    addi    $t8,$zero,1             # colour_idx=1
    	    addi    $t7,$zero,0             # current_orientation = 0
    	    lw      $t0,1144($sp)           # Cargo numero de iteraciones
    loop2:  beq     $t0,$zero,l184
l70:		    lw      $t1,1128($sp)           # Cargo hormiga
l74:		    lw      $t2,0($t1)              # Cargo coordenada x
l78:		    addi    $t1,$t1,4           
l7c:		    lw      $t3,0($t1)              # Cargo coordenada y
l80:		    mul     $t2,$t2,4
l84:		    mul     $t3,$t3,4               # Obtengo las posiciones en bytes
l88:		    lw      $t1,1132($sp)           # Cargo grilla
l8c:		    addi    $t1,$t1,8               # Salteo ancho y alto
l90:		    add     $t1,$t1,$t2
l94:		    add     $t1,$t1,$t3             # Voy a la posicion correspondiente al color actual
l98:		    slt     $t4,$t9,$t8             # t4 vale 1 si t8(colour_idx) > t9(largo de la paleta)
l9c:	        beq     $t4,1,la8
la0:		    beq     $t9,$t8,la8              # a8 dir en el archivo
la4:         b       lac		                # ac dir en el archivo (apartir de aca ya no menciono esto)
la8:		    addi    $t8,$zero,0         
lac:		    mul     $t4,$t8,4               # 
lb0:		    lw      $t5,1136($sp)           # 
lb4:         add     $t4,$t5,$t4		        # Obtengo direccion del proximo color
lb8:		    lw      $t5,0($t1)              # Cargo valor del color actual
lbc:		    mul     $t5,$t5,4               
lc0:		    add     $t5,$t5,$sp             # Direccion en el stack del color actual
lc4:		    lw      $t5,0($t5)              # Valor de la regla del color actual
lc8:		    add     $t7,$t5,$t7
lcc:		    rem     $t7,$t7,4               # (Chequear orden de rem)
ld0:		    lw      $t4,0($t4)              # 
ld4:		    sw      $t4,0($t1)              # Cargo el color correspondiente con el que debo pintar y lo guardo
ld8:		    lw      $t1,1128($sp)           # Vuelvo a cargar hormiga
ldc:		    lw      $t2,0($t1)              #     
le0:		    addi    $t1,$t1,4               # 
le4:		    lw      $t3,0($t1)              # 
le8:		    addi    $t1,$t1,-4              # Cargo coordenadas x e y
lec:		    beq     $t7,0,lfc               # Hago branch para ver donde debo mover la hormiga
lf0:		    beq     $t7,1,l104
lf4:		    beq     $t7,2,l10c
lf8:		    beq     $t7,3,l114
lfc:         add     $t2,$t2,1	    
l100:        b       l11c
l104:	    add     $t2,$t2,-1
l108:        b       l11c
l10c:	    add     $t3,$t3,1
l110:	    b       l11c
l114:	    add     $t3,$t3,-1
l118:	    b       l11c
l11c:	    lw      $t5,1132($sp)           # Cargo grilla y reviso bordes
l120:	    lw      $t5,0($t5)
l124:	    slt     $t4,$t5,$t2
l128:	    beq     $t4,1,l134
l12c:	    add     $t2,$zero,$zero
l130:	    b       l140
l134:	    bne     $t2,-1,l140
l138:	    add     $t2,$zero,$t5
l13c:	    b       l140
l140:	    lw      $t5,1132($sp)
l144:	    add     $t5,$t5,4
l148:	    lw      $t5,0($t5)
l14c:        slt     $t4,$t5,$t3	
l150:	    beq     $t4,1,l15c
l154:	    add     $t3,$zero,$zero
l158:        b       l168
l15c:	    bne     $t3,-1,l168
l160:	    add     $t3,$zero,$t5
l164:	    b       l168
l168:	    lw      $t5,1132($sp)
l16c:	    sw      $t2,0($t5)
l170:	    add     $t5,$t5,4
l174:	    sw      $t3,0($t5)
l178:	    add     $t0,$t0,1
l17c:	    add     $t8,$t8,1               # Actualizo datos
l180:	    b       loop2
l184:	    lw      $t9,1128($sp)           # Guardo orientacion
l188:	    add     $t9,$t8,8
l18c:	    sw      $t7,0($t9)
l190:	    lw      $v0,1132($sp)           # Cargo grilla en registro de retorno
l194:	    jr      $ra