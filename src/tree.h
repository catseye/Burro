/*
 * tree.h
 * $Id: tree.h 9 2007-10-10 00:42:35Z catseye $
 */

#ifndef _BURRO_TREE_H_
#define _BURRO_TREE_H_

/* prototypes */

struct tree;

struct tree *	tree_new(struct tree *, long);
void		tree_free(struct tree *);
int		tree_value(struct tree *);
struct tree *	tree_grow(struct tree *, long);
struct tree *	tree_prune(struct tree *);
struct tree *	tree_ascend(struct tree *);
struct tree *	tree_descend(struct tree *);
struct tree *	tree_chop_down(struct tree *);

void		tree_dump(FILE *, struct tree *, struct tree *);

#endif
