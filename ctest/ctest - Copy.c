
#include <stdio.h>

struct char_node
{ 
	uint8_t data;
	struct char_next_array *next;
};

struct char_next_array
{ 
	uint32_t length;
	struct char_node **ptr;
};

struct track_char_node
{ 
	struct track_char_node *prev;
	struct char_node *node;
};


struct char_node *mytree;
struct char_node *_mytree_node;
struct char_node *_newnode;
struct char_node *_nextnode;
struct char_node **_newarray;
//struct char_node **_oldarrayptr;

struct char_next_array *_constructor;

struct track_char_node *_mytree_path;
struct track_char_node *_next_track_node;

//uint32_t _newlength;
uint8_t bool;
uint32_t n;
uint32_t _tmplength;
uint32_t _i;

char main(void)
{
	mytree = 0;
	_mytree_node = mytree;
	_mytree_path = 0;

	// https://stackoverflow.com/a/5441963
	// https://stackoverflow.com/a/3766358

	bool = 1;
	n = 0;

	// add one node

	if (_mytree_node == 0) {
		_nextnode = 0;
	} else {
		_nextnode = _mytree_node -> next -> ptr[n];
	}
	
	// create a node
	_newnode = (struct char_node *)malloc(sizeof(struct char_node));
	_newnode -> data = bool;

	// create an intermediary "next" array
	_constructor = (struct char_next_array *)malloc(sizeof(struct char_next_array));
	_constructor -> length = n + 1;
	_constructor -> ptr = (struct char_node **)calloc(1 * sizeof(struct char_node));
	_newnode -> next = _constructor;
	_newnode -> next -> ptr[n] = _nextnode;
	
	// add the new node to the existing tree
	if (_mytree_node == 0) {
		mytree = _newnode;
		_mytree_node = mytree;
	} else {
		_mytree_node = mytree;
		_mytree_node -> next -> ptr[n] = _newnode;
	}




	bool = 1;
	n = 0;

	// add another node

	if (_mytree_node == 0) {
		_nextnode = 0;
	} else {
		_nextnode = _mytree_node -> next -> ptr[n];
	}
	
	// create a node
	_newnode = (struct char_node *)malloc(sizeof(struct char_node));
	_newnode -> data = bool;

	// create an intermediary "next" array
	_constructor = (struct char_next_array *)malloc(sizeof(struct char_next_array));
	_constructor -> length = n + 1;
	_constructor -> ptr = (struct char_node **)calloc(1 * sizeof(struct char_node));
	_newnode -> next = _constructor;
	_newnode -> next -> ptr[n] = _nextnode;
	
	// add the new node to the existing tree
	if (_mytree_node == 0) {
		mytree = _newnode;
		_mytree_node = mytree;
	} else {
		_tmplength = _mytree_node -> next -> length;

		if (_tmplength < n) {
			_newarray = (struct char_node **)calloc(n * sizeof(struct char_node));

			_i = 0;
			for ( ; _i <= n; _i++ ) {
				_newarray[n] = _mytree_node -> next -> ptr[n];
				printf("%d", n);	printf("\n");
			}

			_mytree_node = mytree;
			free(_mytree_node -> next -> ptr[n]);
			_mytree_node -> next -> ptr[n] = _newnode;
		}

		_mytree_node = mytree;
		_mytree_node -> next -> ptr[n] = _newnode;
	}



	// add a new tracking node

	_next_track_node = (struct track_char_node *)malloc(sizeof(struct track_char_node));
	_next_track_node -> prev = _mytree_path;
	_next_track_node -> node = _mytree_node;
	_mytree_path = _next_track_node;

//	_mytree_node = _mytree_node -> next -> ptr[n];

//	_i = _mytree_node -> next -> length;
//	_i = _i - 1;
//	_mytree_node = _mytree_node -> next -> ptr[_i];

//	_mytree_node = _mytree_path -> node;
//	free(_mytree_path);
//	_mytree_path = 0;

	_i = 0;
	while (_i == 0) {
		if (_mytree_path == 0) {
			break;
		} else {
			_next_track_node = _mytree_path -> prev;
			_mytree_node = _mytree_path -> node;
			free(_mytree_path);
			_mytree_path = _next_track_node;
		}
	}

	printf("%d", _mytree_node -> data);	printf("\n");

	// free memory allocated to nodes
	free(_mytree_node -> next);
	free(_mytree_node);

	return 0;
}

