
//
// list.h
//
// Copyright (c) 2010 TJ Holowaychuk <tj@vision-media.ca>
//
//

#ifndef __LINKED_LIST_BASE_H__
#define __LINKED_LIST_BASE_H__

#ifdef __cplusplus
extern "C" {
#endif

#include <stdlib.h>

// Library version

#define LINKED_LIST_VERSION "0.0.6"

// Memory management macros

#ifndef LINKED_LIST_MALLOC
#define LINKED_LIST_MALLOC malloc
#endif

#ifndef LINKED_LIST_FREE
#define LINKED_LIST_FREE free
#endif

/*
 * list_t iterator direction.
 */

typedef enum {
    LINKED_LIST_HEAD
  , LINKED_LIST_TAIL
} linked_list_direction_t;

/*
 * list_t node struct.
 */

typedef struct linked_list_node_t {
  struct linked_list_node_t *prev;
  struct linked_list_node_t *next;
  void *val;
} linked_list_node_t;

/*
 * list_t struct.
 */

typedef struct {
  linked_list_node_t *head;
  linked_list_node_t *tail;
  unsigned int len;
  void (*free)(void *val);
  int (*match)(void *a, void *b); // return 0 if equal
  int (*comp)(void *a, void *b);
} linked_list_t;

/*
 * list_t iterator struct.
 */

typedef struct {
  linked_list_node_t *next;
  linked_list_direction_t direction;
} linked_list_iterator_t;

// Node prototypes.

linked_list_node_t *
linked_list_node_new(void *val);

// list_t prototypes.

linked_list_t *
linked_list_new();

linked_list_node_t *
linked_list_node_rpush(linked_list_t *self, linked_list_node_t *node);

linked_list_node_t *
linked_list_node_lpush(linked_list_t *self, linked_list_node_t *node);

linked_list_node_t *
linked_list_node_find(linked_list_t *self, void *val);

linked_list_node_t *
linked_list_node_at(linked_list_t *self, int index);

linked_list_node_t *
linked_list_node_rpop(linked_list_t *self);

linked_list_node_t *
linked_list_node_lpop(linked_list_t *self);

void
linked_list_node_remove(linked_list_t *self, linked_list_node_t *node);

void
linked_list_node_detach(linked_list_t *self, linked_list_node_t *node);

void
linked_list_destroy(linked_list_t *self);

// list_t iterator prototypes.

linked_list_iterator_t *
linked_list_node_iterator_new(linked_list_t *list, linked_list_direction_t direction);

linked_list_iterator_t *
linked_list_node_iterator_new_from_node(linked_list_node_t *node, linked_list_direction_t direction);

linked_list_node_t *
linked_list_node_iterator_next(linked_list_iterator_t *self);

void
linked_list_node_iterator_destroy(linked_list_iterator_t *self);

    
//hw
void* linked_list_sort_push(linked_list_t *self, void* val);
void* linked_list_single_sort_push(linked_list_t *self, void* val);
void* linked_list_rpush(linked_list_t *self, void* val);
void* linked_list_lpush(linked_list_t *self, void* val);
void* linked_list_at(linked_list_t *self, int index);
void* linked_list_rpop(linked_list_t *self);
void* linked_list_lpop(linked_list_t *self);
void linked_list_remove(linked_list_t *self, void* val);

void linked_list_clear(linked_list_t *self);
size_t linked_list_size(linked_list_t *self);
void linked_list_set_value_discard(linked_list_t* self, void(*discard)(void*));

void* linked_list_head(linked_list_t *self);
void* linked_list_tail(linked_list_t *self);

linked_list_node_t* linked_list_rpush2(linked_list_t* self, void* val);
void linked_list_touch(linked_list_t* self, linked_list_node_t* node);
    
#define linked_list_foreach(list, block) \
if ((list)->len > 0) { \
    linked_list_node_t *__node = NULL; \
    linked_list_node_t *__node_next = (list)->head; \
    while ((__node = __node_next) != NULL) { \
        void* val = __node->val; \
        __node_next = __node->next; \
        block; \
    } \
}

#define linked_list_foreach_back(list, block) \
if ((list)->len > 0) { \
    linked_list_node_t *__node = NULL; \
    linked_list_node_t *__node_prev = (list)->tail; \
    while ((__node = __node_prev) != NULL) { \
        void* val = __node->val; \
        __node_prev = __node->prev; \
        block; \
    } \
}
    
#ifdef __cplusplus
}
#endif

#endif /* __LIST_H__ */
