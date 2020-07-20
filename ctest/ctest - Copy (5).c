
#include <stdio.h>

struct char_node
{ 
	uint8_t data;
//	struct char_next_array *next;
	uint64_t length;
	struct char_node **ptr;
};

//struct char_next_array
//{ 
//	uint64_t length;
//	struct char_node **ptr;
//};

struct track_char_node
{ 
	struct track_char_node *prev;
	struct char_node *node;
};

char main(void)
{

	struct char_node *_newnode;
	struct char_node *_nextnode;
	struct char_node **_newarray;
	struct char_next_array *_constructor;
	struct track_char_node *_next_track_node;
	
	//uint32_t _newlength;
	uint8_t bool;
	uint64_t n;
	uint64_t m;
	uint64_t _tmplength;
	uint64_t _i;
	
	struct char_node *mytree = 0;
	struct char_node *_mytree_node;
	struct track_char_node *_mytree_path = 0;

	// https://stackoverflow.com/a/5441963
	// https://stackoverflow.com/a/3766358


	_mytree_node = mytree;

	bool = 1;
	m = 0;
	n = m + 1;

	// create a node
	_newnode = (struct char_node *)malloc(sizeof(struct char_node));
	_newnode -> ptr = (struct char_node **)calloc(n * sizeof(struct char_node));
	_newnode -> data = bool;
	_newnode -> length = n;

	// add the new node to the existing tree
	if (_mytree_node == 0) {
		mytree = _newnode;
		_mytree_node = mytree;
	} else {
		_mytree_node = mytree;
		_mytree_node -> ptr[m] = _newnode;
	}



	// add a new tracking node

	_next_track_node = (struct track_char_node *)malloc(sizeof(struct track_char_node));
	_next_track_node -> prev = _mytree_path;
	_next_track_node -> node = _mytree_node;
	_mytree_path = _next_track_node;


	// go to the next node

	_mytree_node = _mytree_node -> ptr[m];


	bool = 0;
	m = 0;
	n = m + 1;

	// create a node
	_newnode = (struct char_node *)malloc(sizeof(struct char_node));
	_newnode -> ptr = (struct char_node **)calloc(n * sizeof(struct char_node));
	_newnode -> data = bool;
	_newnode -> length = n;

	// add the new node to the existing tree
	if (_mytree_node == 0) {
		mytree = _newnode;
		_mytree_node = mytree;
	} else {
		_mytree_node = mytree;
		_mytree_node -> ptr[m] = _newnode;
	}


	// go to the last node pointer

//	_i = _mytree_node -> length;
//	_i = _i - 1;
//	_mytree_node = _mytree_node -> ptr[_i];


	// go up the tree one node

//	_mytree_node = _mytree_path -> node;
//	_next_track_node = _mytree_path -> prev;
//	free(_mytree_path);
//	_mytree_path = _next_track_node;

	// delete all tracking nodes (to return to the root of the tree)

//	_i = 0;
//	while (_i == 0) {
//		if (_mytree_path == 0) {
//			break;
//		} else {
//			_next_track_node = _mytree_path -> prev;
//			_mytree_node = _mytree_path -> node;
//			free(_mytree_path);
//			_mytree_path = _next_track_node;
//		}
//	}


	// set old node pointer to null

//	for (_i = 0; _i < _tmplength; _i++) {
//		if (_mytree_path != 0) {
//			if (_mytree_node == _mytree_path -> node -> ptr[_i]) {
//				_mytree_path -> node -> ptr[_i] = 0;
//			}
//		}
//	}

	// delete the current node

//	if (_mytree_node -> ptr != 0) {
//		free(_mytree_node -> ptr);
//	}
//	free(_mytree_node);

//	_mytree_node = _mytree_path -> node;		// move to previous node

	// remove most recent node from path

//	_next_track_node = _mytree_path -> prev;
//	free(_mytree_path);
//	_mytree_path = _next_track_node;


	// resize the next pointer array

//	if (_mytree_path != 0) {

//		_tmplength = _mytree_path -> node -> length;

//		_i = _tmplength;
//		for (; _i > 0; _i = _i - 1) {
//			if (_mytree_path -> node -> ptr[_i-1] != 0) {
//				break;
//			}
//		}

//		if (_i = 0) {
//			free(_mytree_node -> ptr);
//			_mytree_node -> ptr = 0;
//		} else {
//			if (_i < _tmplength) {
//				_tmplength = _i;
//				_newarray = (struct char_node **)calloc(_tmplength * sizeof(struct char_node));

//				_i = 0;
//				for ( ; _i <= _tmplength; ) {
//					_newarray[_i] = _mytree_node -> ptr[_i];
//					_i++;
//				}
	
//				free(_mytree_node -> ptr);
//				_mytree_node -> ptr = _newarray;
//			}
//		}
//	}

//	printf("%d", _mytree_path -> node -> ptr[0]);	printf("\n");
//	printf("%d", _mytree_node);		printf("\n");
//	printf("%d", _mytree_path -> node -> ptr[0]);	printf("\n");
//	printf("%d", _mytree_path -> prev);		printf("\n");

//	_tmplength = _mytree_path -> node -> length;
//	printf("%d", _tmplength);	printf("\n");

	printf("%d", _mytree_node -> data);	printf("\n");


	return 0;
}

