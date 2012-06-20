# Makefile for Burro.

HC=ghc
HCFLAGS=-O
O=.o
PROG=Burro

OBJS=Burro${O}

all: ${PROG}

Burro${O}: Burro.lhs
	${HC} ${HCFLAGS} -c $*.lhs

${PROG}: ${OBJS}
	${HC} -o ${PROG} -O ${OBJS}
	strip ${PROG}

clean:
	rm -rf *${O} *.hi ${PROG}
