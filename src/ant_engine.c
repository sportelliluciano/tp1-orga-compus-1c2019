#include "ant_engine.h"

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "artist_ant.h"

typedef uint32_t uintvector_t;

// Gets the length, in elements, of an array.
#define array_size(a) (sizeof(a) / sizeof(a[0]))

// Gets the length of a uintvector_t*
#define UINTV_LEN(intv) (*(intv - 1))

#define X 0
#define Y 1

#ifdef DEBUG_PRINT
const char *strcolour(colour_t col) {
  switch(col) {
    case RED:
      return "RED";
    case BLUE:
      return "BLUE";
    case GREEN:
      return "GREEN";
    case YELLOW: 
      return "YELLOW";
    case BLACK:
      return "BLACK";
    case WHITE:
      return "WHITE";
    default:
      return "WTF MAN";
  }
}

const char *strorientation(orientation_t ori) {
  switch(ori) {
    case NORTH:
      return "NORTH";
    case SOUTH:
      return "SOUTH"; 
    case EAST:
      return "EAST";
    case WEST:
      return "WEST";
    default:
      return "WTFFFFF MAN";
  }
}
#endif

void*
paint(void *ant, void *grid, void *palette, void *rules,  uint32_t iterations)
{
  ant_t *sant = ant;
  square_grid_t *sgrid = grid;

  orientation_t orientation[] = {ON, OE, OS, OW};
  int current_orientation = 0;

  int increments[array_size(orientation)][2] = {
    {0, sgrid->height - 1}, // ON
    {1, 0},                 // OE
    {0, 1},                 // OS
    {sgrid->width - 1, 0}   // OW
  };

  uintvector_t *colours = palette;
  uintvector_t *urules = rules;

  int rules_map[10];
  for (uint32_t i=0; i<UINTV_LEN(colours); i++) {
    rules_map[colours[i]] = urules[i];
  }
  
  for (uint32_t i = 0; i < iterations; i++) {
    colour_t current_colour = sgrid->grid[sant->x][sant->y];
    uint32_t current_turn = rules_map[current_colour];
    colour_t next_colour = colours[(i + 1) % UINTV_LEN(colours)];

    // Change orientation
    current_orientation = (current_orientation + current_turn) % array_size(orientation);
    sant->o = orientation[current_orientation];

    // Paint the cell
    sgrid->grid[sant->x][sant->y] = next_colour;

#ifdef DEBUG_PRINT
    printf("ant is in (%d, %d), old colour: %s, orientation: %s; painted: %s\n",
      sant->x, sant->y, strcolour(current_colour), 
      strorientation(sant->o), 
      strcolour(sgrid->grid[sant->x][sant->y]));
#endif

    // Move to next cell
    sant->x = (sant->x + increments[current_orientation][X]) % sgrid->width;
    sant->y = (sant->y + increments[current_orientation][Y]) % sgrid->height;
  }

  return grid;
}

static uintvector_t* str_to_uintvector(char *str) {
  uint32_t n_chars = 0, n_data = 0;
  while (str[n_chars]) {
    if (str[n_chars] != '|')
      n_data++;
    n_chars++;
  }

  // sizeof(*vector) es una desreferencia mágica. Thanks god se resuelve
  //  en tiempo de compilación!
  uintvector_t *vector = malloc(sizeof(*vector) * (n_data + 1));
  if (!vector)
    return NULL;

  vector[0] = n_data;

  for (uint32_t i = 0, j = 1; i < n_chars; i++) {
    if (str[i] != '|')
      vector[j++] = str[i];
  }

  return vector + 1;
}

void*
make_rules(char *spec)
{
  uintvector_t* rules = str_to_uintvector(spec);
  for (uint32_t i=0;i<UINTV_LEN(rules);i++) {
    rules[i] = (rules[i] == 'L') ? 3:1;
  }
  return rules;
}

static colour_t
get_colour(char c)
{
  static char * index = "RGBYNW";
  char *p = strchr(index, c);
  return (p - index);
}

void*
make_palette(char *colours)
{
  uintvector_t *palette = str_to_uintvector(colours);
  for (uint32_t i=0;i<UINTV_LEN(palette);i++) {
    palette[i] = get_colour(palette[i]);
  }
  return palette;
}

