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
 * tree.c
 *
 * Decision-saving trees (continuations) for Burro.
 *
 * $Id: tree.c 9 2007-10-10 00:42:35Z catseye $
 */

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#include "tree.h"

/* private structures */

struct tree {
	struct tree *		parent;
	struct child_list *	children;
	long			value;
};

struct child_list {
	struct child_list *	next;
	struct tree *		child;
};

/* private methods */

static struct child_list *
child_list_new(struct tree *child)
{
	struct child_list *cl;

	cl = malloc(sizeof(struct child_list));
	assert(cl != NULL);
	cl->next = NULL;
	cl->child = child;

	return cl;
}

static void
child_list_free(struct child_list *cl)
{
	if (cl == NULL)
		return;
	child_list_free(cl->next);
	tree_free(cl->child);
}

/* public methods */

struct tree *
tree_new(struct tree *parent, long value)
{
	struct tree *t;

	t = malloc(sizeof(struct tree));
	assert(t != NULL);
	t->parent = parent;
	t->children = NULL;
	t->value = value;

	return t;
}

void
tree_free(struct tree *t)
{
	if (t == NULL)
		return;
	child_list_free(t->children);
	free(t);
}

int
tree_value(struct tree *t)
{
	assert(t != NULL);
	return t->value;
}

/*
 * Add a degenerate subtree to the current level of the tree.
 */
struct tree *
tree_grow(struct tree *parent, long value)
{
	struct tree *t;
	struct child_list *cl;

	assert(parent != NULL);

	/* create new node and new child entry */
	t = tree_new(parent, value);
	cl = child_list_new(t);

	/* add new child at start of children list */
	/* this makes it a lot like a stack... */
	cl->next = parent->children;
	parent->children = cl;

	return t;
}

/*
 * Return the parent of the given subtree.
 */
struct tree *
tree_ascend(struct tree *t)
{
	assert(t != NULL);
	return t->parent;
}

/*
 * Return the last (most recently added) subtree.
 */
struct tree *
tree_descend(struct tree *t)
{
	assert(t != NULL);
	assert(t->children != NULL);
	return t->children->child;
}

/*
 * Remove the given subtree from the tree.
 */
struct tree *
tree_prune(struct tree *t)
{
	struct tree *p;
	struct child_list *cl, *ocl;

	assert(t != NULL);
	assert(t->parent != NULL);

	p = t->parent;

	/* find the correct child */
	cl = p->children;
	ocl = NULL;
	while (cl != NULL && cl->child != t) {
		ocl = cl;
		cl = cl->next;
	}
	assert(cl != NULL);
	if (ocl != NULL) {
		ocl->next = cl->next;
	} else {
		p->children = cl->next;
	}
	child_list_free(cl);

	return p;
}

/*
 * Dispose of everything except the root.
 */
struct tree *
tree_chop_down(struct tree *root)
{
	child_list_free(root->children);

	root->children = NULL;

	return root;
}

/*
 * Dump a representation of the tree to a file.
 */
void
tree_dump(FILE *f, struct tree *t, struct tree *save)
{
	struct child_list *cl;

	if (t == NULL)
		return;
	if (t == save)
		fprintf(f, "->");
	if (t->parent == NULL) {
		fprintf(f, "(R ");
	} else {
		fprintf(f, "(%ld ", t->value);
	}
	cl = t->children;
	while (cl != NULL) {
		tree_dump(f, cl->child, save);
		cl = cl->next;
	}
	fprintf(f, ")");
}
