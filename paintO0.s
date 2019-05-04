.text
.globl Paint

Paint:
0:		    addiu   $sp,$sp,-1128
4:		    sw      $a0,1128($sp)
8:		    sw      $a1,1132($sp)
c:		    sw      $a2,1136($sp)
10:		    sw      $a3,1140($sp)
14:		    lw      $v0,1144($sp)
18:		    lw      $t0,1136($sp)           //Cargo paleta
1c:		    lw      $t8,1140($sp)           //Cargo reglas
20:		    addi    $t0,$t0,-4
24:		    lw      $t1,0($t0)
28:		    addi    $t0,$t0,4
2c:	Loop1:  beq     $t1,$zero,54            //Dir 54 del archivo es donde debe seguir
30:		    lw      $t2,0($t0)              //Cargo color actual
34:		    mul     $t2,$t2,4               //Obtengo la pos del color en el stack
38:		    add     $t2,$t2,$sp             //Me muevo al sp+pos en el stack
3c:		    lw      $t3,0($t8)              //Cargo regla
40:		    sw      $t3,0($t2)              //Guardo regla en la pos correspondiente
44:		    addi    $t0,4,$t0               //Avanzo puntero
48:		    addi    $t8,4,$t8               //Avanzo puntero
4c:		    addi    $t1,$t1,-1
50:		    b       Loop1
54:		    lw      $t0,1136($sp)           //
58:		    addi    $t0,$t0,-4              //
5c:		    lw      $t9,0($t0)              //Vuelvo a obtener el largo de la paleta
60:		    addi    $t8,$zero,1             //colour_idx=1
64:		    addi    $t7,$zero,$zero         //current_orientation = 0
68:		    lw      $t0,1144($sp)           //Cargo numero de iteraciones
6c: Loop2:  beq     $t0,$zero,184
70:		    lw      $t1,1128($sp)           //Cargo hormiga
74:		    lw      $t2,0($t1)              //Cargo coordenada x
78:		    addi    $t1,$t1,4           
7c:		    lw      $t3,0($t1)              //Cargo coordenada y
80:		    mul     $t2,$t2,4
84:		    mul     $t3,$t3,4               //Obtengo las posiciones en bytes
88:		    lw      $t1,1132($sp)           //Cargo grilla
8c:		    addi    $t1,$t1,8               //Salteo ancho y alto
90:		    add     $t1,$t1,$t2
94:		    add     $t1,$t1,$t3             //Voy a la posicion correspondiente al color actual
98:		    slt     $t4,$t9,$t8             //t4 vale 1 si t8(colour_idx) > t9(largo de la paleta)
9c:	        beq     $t4,1,a8
a0:		    beq     $t9,$t8,a8              //a8 dir en el archivo
a4:         b       ac		                //ac dir en el archivo (apartir de aca ya no menciono esto)
a8:		    addi    $t8,$zero,$zero         
ac:		    mul     $t4,$t8,4               //
b0:		    lw      $t5,1136($sp)           //
b4:         add     $t4,$t5,$t4		        //Obtengo direccion del proximo color
b8:		    lw      $t5,0($t1)              //Cargo valor del color actual
bc:		    mul     $t5,$t5,4               
c0:		    add     $t5,$t5,$sp             //Direccion en el stack del color actual
c4:		    lw      $t5,0($t5)              //Valor de la regla del color actual
c8:		    add     $t7,$t5,$t7
cc:		    rem     $t7,$t7,4               //(Chequear orden de rem)
d0:		    lw      $t4,0($t4)              //
d4:		    sw      $t4,0($t1)              //Cargo el color correspondiente con el que debo pintar y lo guardo
d8:		    lw      $t1,1128($sp)           //Vuelvo a cargar hormiga
dc:		    lw      $t2,0($t1)              //    
e0:		    addi    $t1,$t1,4               //
e4:		    lw      $t3,0($t1)              //
e8:		    addi    $t1,$t1,-4              //Cargo coordenadas x e y
ec:		    beq     $t7,0,fc                //Hago branch para ver donde debo mover la hormiga
f0:		    beq     $t7,1,104
f4:		    beq     $t7,2,10c
f8:		    beq     $t7,3,114
fc:         add     $t2,$t2,1	    
100:        b       11c
104:	    add     $t2,$t2,-1
108:        b       11c
10c:	    add     $t3,$t3,1
110:	    b       11c
114:	    add     $t3,$t3,-1
118:	    b       11c
11c:	    lw      $t5,1132($sp)           //Cargo grilla y reviso bordes
120:	    lw      $t5,0($t5)
124:	    slt     $t4,$t5,$t2
128:	    beq     $t4,1,134
12c:	    add     $t2,$zero,$zero
130:	    b       140
134:	    bne     $t2,-1,140
138:	    add     $t2,$zero,$t5
13c:	    b       140
140:	    lw      $t5,1132($sp)
144:	    add     $t5,$t5,4
148:	    lw      $t5,0($t5)
14c:        slt     $t4,$t5,$t3	
150:	    beq     $t4,1,15c
154:	    add     $t3,$zero,$zero
158:        b       168
15c:	    bne     $t3,-1,168
160:	    add     $t3,$zero,$t5
164:	    b       168
168:	    lw      $t5,1132($sp)
16c:	    sw      $t2,0($t5)
170:	    add     $t5,4,$t5
174:	    sw      $t3,0($t5)
178:	    add     $t0,$t0,1
17c:	    add     $t8,$t8,1               //Actualizo datos
180:	    b       Loop2
184:	    lw      $t9,1128($sp)           //Guardo orientacion
188:	    add     $t9,$t8,8
18c:	    sw      $t7,0($t9)
190:	    lw      $v0,1132($sp)           //Cargo grilla en registro de retorno
194:	    jr      $ra

