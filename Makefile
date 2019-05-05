CFLAGS := -ggdb -O1
CFLAGS += -std=c99 -Wall -Wextra -Wpedantic -fno-inline
CC := gcc

SRCS := $(wildcard src/*.c)
OBJS := $(patsubst src/%.c,obj/%.o,$(SRCS))

tp1: $(OBJS)
	$(CC) $(OBJS) -o tp1

obj/paint.o: src/paint.S
	$(CC) -c $< -o $@

tp1-asm: CFLAGS += -DASSEMBLY_PAINT
tp1-asm: $(OBJS) obj/paint.o
	$(CC) obj/paint.o $(OBJS) -o tp1

obj/%.o: src/%.c
	@mkdir -p obj
	$(CC) $(CFLAGS) -o $@ -c $<

clean:
	rm -rf tp1 *.o core obj

.PHONY: clean
