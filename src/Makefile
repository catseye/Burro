# Makefile for burro.

CC?=gcc
OBJS=burro.o tree.o
PROG=burro

all: $(PROG)

$(PROG): $(OBJS)
	$(CC) $(OBJS) -o $(PROG)

burro.o: burro.c tree.h
	$(CC) -Wall -c burro.c -o burro.o

tree.o: tree.c tree.h
	$(CC) -Wall -c tree.c -o tree.o

clean:
	rm -rf $(OBJS) $(PROG)
