
//
// list.c
//
// Copyright (c) 2010 TJ Holowaychuk <tj@vision-media.ca>
//

#include "linked_list_base.h"

/*
 * Allocate a new list_t. NULL on failure.
 */

linked_list_t *
linked_list_new() {
    linked_list_t *self;
    if (!(self = LINKED_LIST_MALLOC(sizeof(linked_list_t))))
        return NULL;
    self->head = NULL;
    self->tail = NULL;
    self->free = NULL;
    self->match = NULL;
    self->comp = NULL;
    self->len = 0;
    return self;
}

/*
 * Free the list.
 */

void
linked_list_destroy(linked_list_t *self) {
    if(!self){
        return ;
    }
    unsigned int len = self->len;
    linked_list_node_t *next;
    linked_list_node_t *curr = self->head;
    
    while (len--) {
        next = curr->next;
        if (self->free) self->free(curr->val);
        LINKED_LIST_FREE(curr);
        curr = next;
    }
    
    LINKED_LIST_FREE(self);
}

/*
 * Append the given node to the list
 * and return the node, NULL on failure.
 */

linked_list_node_t *
linked_list_node_rpush(linked_list_t *self, linked_list_node_t *node) {
    if (!node) return NULL;
    
    if (self->len) {
        node->prev = self->tail;
        node->next = NULL;
        self->tail->next = node;
        self->tail = node;
    } else {
        self->head = self->tail = node;
        node->prev = node->next = NULL;
    }
    
    ++self->len;
    return node;
}

/*
 * Return / detach the last node in the list, or NULL.
 */

linked_list_node_t *
linked_list_node_rpop(linked_list_t *self) {
    if (!self->len) return NULL;
    
    linked_list_node_t *node = self->tail;
    
    if (--self->len) {
        (self->tail = node->prev)->next = NULL;
    } else {
        self->tail = self->head = NULL;
    }
    
    node->next = node->prev = NULL;
    return node;
}

/*
 * Return / detach the first node in the list, or NULL.
 */

linked_list_node_t *
linked_list_node_lpop(linked_list_t *self) {
    if (!self->len) return NULL;
    
    linked_list_node_t *node = self->head;
    
    if (--self->len) {
        (self->head = node->next)->prev = NULL;
    } else {
        self->head = self->tail = NULL;
    }
    
    node->next = node->prev = NULL;
    return node;
}

/*
 * Prepend the given node to the list
 * and return the node, NULL on failure.
 */

linked_list_node_t *
linked_list_node_lpush(linked_list_t *self, linked_list_node_t *node) {
    if (!node) return NULL;
    
    if (self->len) {
        node->next = self->head;
        node->prev = NULL;
        self->head->prev = node;
        self->head = node;
    } else {
        self->head = self->tail = node;
        node->prev = node->next = NULL;
    }
    
    ++self->len;
    return node;
}

/*
 * Return the node associated to val or NULL.
 */

linked_list_node_t *
linked_list_node_find(linked_list_t *self, void *val) {
    linked_list_iterator_t *it = linked_list_node_iterator_new(self, LINKED_LIST_HEAD);
    linked_list_node_t *node;
    
    while ((node = linked_list_node_iterator_next(it))) {
        if (self->match) {
            if (!self->match(val, node->val)) {
                linked_list_node_iterator_destroy(it);
                return node;
            }
        } else {
            if (val == node->val) {
                linked_list_node_iterator_destroy(it);
                return node;
            }
        }
    }
    
    linked_list_node_iterator_destroy(it);
    return NULL;
}

/*
 * Return the node at the given index or NULL.
 */

linked_list_node_t *
linked_list_node_at(linked_list_t *self, int index) {
    linked_list_direction_t direction = LINKED_LIST_HEAD;
    
    if (index < 0) {
        direction = LINKED_LIST_TAIL;
        index = ~index;
    }
    
    if (index < self->len) {
        linked_list_iterator_t *it = linked_list_node_iterator_new(self, direction);
        linked_list_node_t *node = linked_list_node_iterator_next(it);
        while (index--) node = linked_list_node_iterator_next(it);
        linked_list_node_iterator_destroy(it);
        return node;
    }
    
    return NULL;
}

/*
 * Remove the given node from the list, freeing it and it's value.
 */

void
linked_list_node_remove(linked_list_t *self, linked_list_node_t *node) {
    node->prev
    ? (node->prev->next = node->next)
    : (self->head = node->next);
    
    node->next
    ? (node->next->prev = node->prev)
    : (self->tail = node->prev);
    
    if (self->free) self->free(node->val);
    
    LINKED_LIST_FREE(node);
    --self->len;
}

/*
 * Detach the given node from the list, no free it.
 */

void
linked_list_node_detach(linked_list_t *self, linked_list_node_t *node) {
    node->prev
    ? (node->prev->next = node->next)
    : (self->head = node->next);
    
    node->next
    ? (node->next->prev = node->prev)
    : (self->tail = node->prev);
    
    --self->len;
}

/*
 * Allocates a new list_node_t. NULL on failure.
 */

linked_list_node_t *
linked_list_node_new(void *val) {
    linked_list_node_t *self;
    if (!(self = LINKED_LIST_MALLOC(sizeof(linked_list_node_t))))
        return NULL;
    self->prev = NULL;
    self->next = NULL;
    self->val = val;
    return self;
}


/*
 * Allocate a new list_iterator_t. NULL on failure.
 * Accepts a direction, which may be LIST_HEAD or LIST_TAIL.
 */

linked_list_iterator_t *
linked_list_node_iterator_new(linked_list_t *list, linked_list_direction_t direction) {
    linked_list_node_t *node = direction == LINKED_LIST_HEAD
    ? list->head
    : list->tail;
    return linked_list_node_iterator_new_from_node(node, direction);
}

/*
 * Allocate a new list_iterator_t with the given start
 * node. NULL on failure.
 */

linked_list_iterator_t *
linked_list_node_iterator_new_from_node(linked_list_node_t *node, linked_list_direction_t direction) {
    linked_list_iterator_t *self;
    if (!(self = LINKED_LIST_MALLOC(sizeof(linked_list_iterator_t))))
        return NULL;
    self->next = node;
    self->direction = direction;
    return self;
}

/*
 * Return the next list_node_t or NULL when no more
 * nodes remain in the list.
 */

linked_list_node_t *
linked_list_node_iterator_next(linked_list_iterator_t *self) {
    linked_list_node_t *curr = self->next;
    if (curr) {
        self->next = self->direction == LINKED_LIST_HEAD
        ? curr->next
        : curr->prev;
    }
    return curr;
}

/*
 * Free the list iterator.
 */


void
linked_list_node_iterator_destroy(linked_list_iterator_t *self) {
    LINKED_LIST_FREE(self);
}

//hw

linked_list_node_t *
linked_list_node_sort_push(linked_list_t *self, linked_list_node_t *node) {
    if (!node) return NULL;
    
    if (self->comp == NULL || self->len < 1) {
        return linked_list_node_rpush(self, node);
    }
    
    linked_list_node_t* curr = self->head;
    
    int c = 0;
    while (curr) {
        c = self->comp(node->val, curr->val);
        if(c>0){
            curr = curr->next;
            continue;
        }
        break;
    }
    
    if (curr == NULL) {
        return linked_list_node_rpush(self, node);
    }
    
    if (curr->prev==NULL) {
        node->next = curr;
        node->prev = NULL;
        curr->prev = node;
        self->head = node;
    }else{
        node->next = curr;
        node->prev = curr->prev;
        curr->prev->next = node;
        curr->prev = node;
    }
    
    ++self->len;
    return node;
}

linked_list_node_t *
linked_list_node_single_sort_push(linked_list_t *self, linked_list_node_t *node) {
    if (!node) return NULL;
    
    if (self->comp == NULL || self->len < 1) {
        return linked_list_node_rpush(self, node);
    }
    
    linked_list_node_t* curr = self->head;
    
    int c = 0;
    while (curr) {
        c = self->comp(node->val, curr->val);
        if(c>0){
            curr = curr->next;
            continue;
        }else if(c==0){
            return NULL;
        }
        break;
    }
    
    if (curr == NULL) {
        return linked_list_node_rpush(self, node);
    }
    
    if (curr->prev==NULL) {
        node->next = curr;
        node->prev = NULL;
        curr->prev = node;
        self->head = node;
    }else{
        node->next = curr;
        node->prev = curr->prev;
        curr->prev->next = node;
        curr->prev = node;
    }
    
    ++self->len;
    return node;
}

void* linked_list_sort_push(linked_list_t *self, void* val){
    linked_list_node_t* node = linked_list_node_new(val);
    linked_list_node_sort_push(self, node);
    return val;
}

void* linked_list_single_sort_push(linked_list_t *self, void* val){
    linked_list_node_t* node = linked_list_node_new(val);
    if(NULL == linked_list_node_single_sort_push(self, node)){
        LINKED_LIST_FREE(node);
        return NULL;
    }
     return val;
}

void* linked_list_rpush(linked_list_t *self, void* val){
    linked_list_node_t* node = linked_list_node_new(val);
    linked_list_node_rpush(self, node);
    return val;
}

void* linked_list_lpush(linked_list_t *self, void* val){
    linked_list_node_t* node = linked_list_node_new(val);
    linked_list_node_lpush(self, node);
    return val;
}

void* linked_list_at(linked_list_t *self, int index){
    linked_list_node_t* node = linked_list_node_at(self, index);
    if (node != NULL) {
        return node->val;
    }
    return NULL;
}

void* linked_list_rpop(linked_list_t *self){
    linked_list_node_t* node = linked_list_node_rpop(self);
    if (node == NULL) {
        return NULL;
    }
    void* ret = node->val;
    LINKED_LIST_FREE(node);
    
    return ret;
}

void* linked_list_lpop(linked_list_t *self){
    linked_list_node_t* node = linked_list_node_lpop(self);
    if (node == NULL) {
        return NULL;
    }
    void* ret = node->val;
    LINKED_LIST_FREE(node);
    
    return ret;
}

void linked_list_remove(linked_list_t *self, void* val){
    linked_list_node_t* node = linked_list_node_find(self, val);
    if (node == NULL) {
        return;
    }
    linked_list_node_remove(self, node);
}

void
linked_list_clear(linked_list_t *self) {
    unsigned int len = self->len;
    
    if (len<1) {
        return;
    }
    
    linked_list_node_t *next;
    linked_list_node_t *curr = self->head;
    
    while (len--) {
        next = curr->next;
        if (self->free) self->free(curr->val);
        LINKED_LIST_FREE(curr);
        curr = next;
    }

    self->head = NULL;
    self->tail = NULL;
    self->len = 0;
}

size_t linked_list_size(linked_list_t *self){
    if(self == NULL)
    {
        return 0;
    }
    return self->len;
}

void linked_list_set_value_discard(linked_list_t* self, void(*discard)(void*)){
    if(self == NULL)
    {
        return;
    }
    self->free = discard;
}

void* linked_list_head(linked_list_t *self)
{
    return self->head == NULL ? NULL : self->head->val;
}

void* linked_list_tail(linked_list_t *self)
{
    return self->tail == NULL ? NULL : self->tail->val;
}

linked_list_node_t* linked_list_rpush2(linked_list_t* self, void* val)
{
    return linked_list_node_rpush(self, linked_list_node_new(val));
}

void linked_list_touch(linked_list_t* self, linked_list_node_t* node)
{
    if (self == NULL || node == NULL) {
        return;
    }
    
    node->prev
    ? (node->prev->next = node->next)
    : (self->head = node->next);
    
    node->next
    ? (node->next->prev = node->prev)
    : (self->tail = node->prev);
    
    if (self->len - 1) {
        node->prev = self->tail;
        node->next = NULL;
        self->tail->next = node;
        self->tail = node;
    } else {
        self->head = self->tail = node;
        node->prev = node->next = NULL;
    }
    
}

