CFLAGS := -ggdb -O1
CFLAGS += -std=c99 -Wall -Wextra -Wpedantic -fno-inline
CC := gcc

SRCS := $(wildcard src/*.c)
OBJS := $(patsubst src/%.c,obj/%.o,$(SRCS))

tp1: $(OBJS)

obj/%.o: src/%.c
	@mkdir -p obj
	$(CC) $(CFLAGS) -o $@ -c $<

clean:
	rm -rf tp1 *.o core obj

.PHONY: clean
