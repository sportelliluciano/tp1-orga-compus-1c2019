#include "ant_engine.h"

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "artist_ant.h"

typedef uint32_t uintvector_t;

// Gets the length of a uintvector_t*
#define UINTV_LEN(intv) (*(intv - 1))

#define X 0
#define Y 1

void*
paint(void *ant, void *grid, void *palette, void *rules,  uint32_t iterations)
{
  char *rules_str = rules;
  ant_t *sant = ant;
  square_grid_t *sgrid = grid;

  orientation_t orientation[] = {ON, OE, OS, OW};
  int current_orientation = 0;

  int increments[4][2] = {{0, 1}, {1, 0}, {0, -1}, {-1, 0}};

  uintvector_t *colours = palette;
  uint32_t colour_idx = 1;

  int rules_map[256];
  for (uint32_t i=0; i<UINTV_LEN(colours); i++) {
    rules_map[colours[i]] = rules_str[i];
  }
  
  for (uint32_t i = 0; i < iterations; i++, colour_idx++) {
    colour_t current_colour = sgrid->grid[sant->y][sant->x];
    
    if (colour_idx >= UINTV_LEN(colours))
      colour_idx = 0;
    colour_t next_colour = colours[colour_idx];

    // Change orientation
    current_orientation = (current_orientation + rules_map[current_colour]) % 4;
    sant->o = orientation[current_orientation];

    // Paint the cell
    sgrid->grid[sant->y][sant->x] = next_colour;
    
    // Move to next cell
    sant->x += increments[current_orientation][X];
    sant->y += increments[current_orientation][Y];

    // Check boundaries
    if (sant->x > sgrid->width) 
      sant->x = 0;
    else if (sant->x == (uint32_t)-1) // sant->x is unsigned > check overflow
      sant->x = sgrid->width - 1;
    if (sant->y > sgrid->height)
      sant->y = 0;
    else if (sant->y == (uint32_t)-1)
      sant->y = sgrid->height - 1;
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

