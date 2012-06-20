/*
 * Copyright (c)2005-2007 Cat's Eye Technologies.  All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *   Redistributions of source code must retain the above copyright
 *   notices, this list of conditions and the following disclaimer.
 *
 *   Redistributions in binary form must reproduce the above copyright
 *   notices, this list of conditions, and the following disclaimer in
 *   the documentation and/or other materials provided with the
 *   distribution.
 *
 *   Neither the names of the copyright holders nor the names of their
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * burro.c
 *
 * A quick-and-dirty interpreter for the Burro programming language,
 * where the set of possible programs is a group under concatenation
 * (roughly speaking; see burro.html for the full story.)
 *
 * $Id: burro.c 10 2007-10-10 01:17:52Z catseye $
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>	/* for getopt() */

#include "tree.h"

/* constants */

#ifndef TAPE_SIZE
#define TAPE_SIZE 65536
#endif

#define TAPE_START	(TAPE_SIZE / 2)		/* for entry and dump */
#define TAPE_END	(TAPE_START + 100)	/* for dumps only */

#ifndef PROG_SIZE
#define	PROG_SIZE 65536
#endif

/* globals */

char prog[PROG_SIZE];
int pc;

long tape[TAPE_SIZE];
int th;

int halt_flag;

int debug_flag = 0;

FILE *f;

struct tree *root;	/* structure into which we save test results */

/********* debugging *********/

void
debug_state(void)
{
	if (!debug_flag)
		return;

	fprintf(stderr,
	    "OP='%c' PC=%3d TH=%3d TC=%4ld HF=%1d ",
	    prog[pc], pc, th - TAPE_START, tape[th], halt_flag);
}

void
debug_tree(struct tree *t, struct tree *s)
{
	if (!debug_flag)
		return;
	tree_dump(stderr, t, s);
}

void
debug_newline(void)
{
	if (debug_flag)
		fprintf(stderr, "\n");
}

/**** usage info ****/

void
usage(void)
{
	fprintf(stderr, "Usage: burro [-d] filename\n");
	exit(1);
}

/**** MAIN ****/

int
main(int argc, char **argv)
{
	int ch;			/* getopt character */
	struct tree *save;
	int i;

	/* get cmdline args */
	while ((ch = getopt(argc, argv, "d")) != -1) {
		switch ((char)ch) {
		case 'd':
			debug_flag++;
			break;
		case '?':
		default:
			usage();
		}
	}
	argv += optind;
	argc -= optind;

	if (argc < 1)
		usage();

	/* load */

	f = fopen(argv[0], "r");
	if (f == NULL) {
		fprintf(stderr, "Couldn't open '%s'\n", argv[0]);
		exit(1);
	}
	pc = 0;
	for (;;) {
		if (pc >= PROG_SIZE) break;
		prog[pc] = fgetc(f);
		if (feof(f)) break;
		if (strchr("+-<>(/){\\}!e", prog[pc]) == NULL) continue;
		pc++;
	}
	prog[pc] = '\0';
	fclose(f);

	/* initialize tape */

	for (th = 0; th < TAPE_SIZE; th++)
		tape[th] = 0;

	/* read tape from input */

	th = TAPE_START;
	for (;;) {
		scanf("%ld", &tape[th]);
		if (feof(stdin)) {
			tape[th] = 0;
			break;
		}
		if (debug_flag) {
			fprintf(stderr,
			    "Writing %ld into position %d\n",
			    tape[th], th);
		}
		th++;
	}

	/* initialize decision-save-tree */

	root = tree_new(NULL, 0);
	save = root;

	/* run */

	th = TAPE_START;

	do {
		/* once through */
		halt_flag = 1;
		for (pc = 0; prog[pc] != '\0'; pc++) {
			switch (prog[pc]) {
			case '>':
				th++;
				break;
			case '<':
				th--;
				break;
			case '+':
				tape[th]++;
				break;
			case '-':
				tape[th]--;
				break;
			case '(':
				save = tree_grow(save, tape[th]);
				if (tape[th] == 0) {
					/* skip to matching / or ) */
					int bc = 1;

					pc++;
					for (; prog[pc] != '\0'; pc++) {
						if (prog[pc] == '(')
							bc++;
						if (prog[pc] == '/' && bc == 1)
							break;
						if (prog[pc] == ')') {
							bc--;
							if (bc == 0) {
								save = tree_ascend(save);
								break;
							}
						}
					}
				}
				break;
			case '/':
				/* skip to matching ) */
				{
					int bc = 1;

					pc++;
					for (; prog[pc] != '\0'; pc++) {
						if (prog[pc] == '(')
							bc++;
						if (prog[pc] == ')') {
							bc--;
							if (bc == 0) {
								save = tree_ascend(save);
								break;
							}
						}
					}
				}
				break;
			case ')':
				save = tree_ascend(save);
				break;
			case '{':
				save = tree_descend(save);
				if (tree_value(save) == 0) {
					/* skip to matching \ or } */
					int bc = 1;

					pc++;
					for (; prog[pc] != '\0'; pc++) {
						if (prog[pc] == '{')
							bc++;
						if (prog[pc] == '\\' && bc == 1)
							break;
						if (prog[pc] == '}') {
							bc--;
							if (bc == 0) {
								save = tree_prune(save);
								break;
							}
						}
					}
				}
				break;
			case '\\':
				/* skip to matching } */
				{
					int bc = 1;

					pc++;
					for (; prog[pc] != '\0'; pc++) {
						if (prog[pc] == '{')
							bc++;
						if (prog[pc] == '}') {
							bc--;
							if (bc == 0) {
								save = tree_prune(save);
								break;
							}
						}
					}
				}
				break;
			case '}':
				save = tree_prune(save);
				break;
			case '!':
				halt_flag = !halt_flag;
				break;
			case 'e':
				/* nop */
				break;
			}
			debug_state();
			debug_tree(root, save);
			debug_newline();
		}
		if (debug_flag) {
			fprintf(stderr, "Reached end of program; %s.\n",
			    halt_flag ? "halting" : "looping");
		}
		/* clear savetree */
		save = tree_chop_down(root);
	} while (!halt_flag);

	/* dump tape to output */

	for (i = TAPE_START; i < TAPE_END; i++) {
		if (i == th)
			printf(">%ld< ", tape[i]);
		else
			printf("%ld ", tape[i]);
	}
	printf("\n");

	return 0;
}
