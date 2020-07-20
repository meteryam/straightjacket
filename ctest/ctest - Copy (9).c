
#include <stdio.h>

struct _int08_node
{ 
	uint8_t data;
	uint64_t length;
	struct _int08_node **ptr;
};

struct _track_int08_node
{ 
	struct _track_int08_node *prev;
	struct _int08_node *node;
};

void deltree(struct _int08_node **tree, struct _int08_node **tree_node, struct _track_int08_node **path)
{
	struct _int08_node *_comparenode;
	struct _track_int08_node *_next_track_node;

	uint64_t _tmplength;
	int64_t _i;

	*tree_node = *tree;

	if (*tree > 0)		// skip null-valued trees
	{
		for(;;)
		{
			_tmplength = (*tree_node) -> length;
	
			if (_tmplength > 0)
			{
				_tmplength = _tmplength - 1;
				_i = _tmplength;

				// loop through the pointer list to find non-zero pointers

				for(;_i >= 0; _i = _i - 1)
				{
					_comparenode = (*tree_node) -> ptr[_i];

					if (_comparenode > 0) 	// use a depth-first search
					{
						*tree_node = (*tree_node) -> ptr[_i];
						break; 
					}
				}

				if (_comparenode == 0)	// all pointer array entries have been zeroed out
				{
					free((*tree_node) -> ptr);
					(*tree_node) -> length = 0;
				}


			} else {
				free(*tree_node);

				if (*path == 0) 				// found the tree root
				{
					*tree = 0;
					*tree_node = *tree;
					break;

				} else {

					_i = (*path) -> node -> length;
					_i = _i - 1;

					for(;_i >= 0; _i = _i - 1)
					{
						_comparenode = (*path) -> node -> ptr[_i];
	
						if (_comparenode == *tree_node)
						{
							(*path) -> node -> ptr[_i] = 0;
							break; 
						}
					}
	
					// move back up the tree

					*tree_node = (*path) -> node;
					_next_track_node = (*path) -> prev;
					free(*path);
					*path = _next_track_node;
	
				}

			}
		}
	}


	return;
}

uint16_t main(void)
{

	struct _int08_node *mytree = 0;
	struct _int08_node *_mytree_node;
	struct _int08_node *_newnode;
	struct _int08_node *_nextnode;
	struct _int08_node *_comparenode;

	struct _int08_node **_newarray;

	struct _track_int08_node *_mytree_path = 0;
	struct _track_int08_node *_next_track_node;
	
	uint8_t bool;
	uint64_t n;
	uint64_t m;
	uint64_t _tmplength;
	int64_t _i;

	_mytree_node = mytree;

	bool = 1;
	m = 0;
	n = m + 1;

	// create a node
	_newnode = (struct _int08_node *)calloc(sizeof(struct _int08_node));
	_newnode -> data = bool;

	// add the new node to the existing tree
	if (_mytree_node == 0) {
		mytree = _newnode;
		_mytree_node = mytree;
	} else if (_mytree_node -> ptr == 0) {
		_mytree_node -> ptr = (struct _int08_node **)calloc(n * sizeof(struct _int08_node*));
		_mytree_node -> ptr[m] = _newnode;
		_mytree_node -> length = n;
	} else {
		_mytree_node -> ptr[m] = _newnode;
		_mytree_node -> length = n;
	}


	// add a new tracking node

	_next_track_node = (struct _track_int08_node *)malloc(sizeof(struct _track_int08_node));
	_next_track_node -> prev = _mytree_path;
	_next_track_node -> node = _mytree_node;
	_mytree_path = _next_track_node;



	bool = 0;
	m = 0;
	n = m + 1;

	// create a node
	_newnode = (struct _int08_node *)calloc(sizeof(struct _int08_node));
	_newnode -> data = bool;

	// add the new node to the existing tree
	if (_mytree_node == 0) {
		mytree = _newnode;
		_mytree_node = mytree;
	} else if (_mytree_node -> ptr == 0) {
		_mytree_node -> ptr = (struct _int08_node **)calloc(n * sizeof(struct _int08_node*));
		_mytree_node -> ptr[m] = _newnode;
		_mytree_node -> length = n;
	} else {
		_mytree_node -> ptr[m] = _newnode;
		_mytree_node -> length = n;
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
//				_newarray = (struct _int08_node **)calloc(_tmplength * sizeof(struct _int08_node*));

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



//	printf("%d", _mytree_node -> data);	printf("\n");


	// delete entire tree


	deltree(&mytree, &_mytree_node, &_mytree_path);

	printf("%d", _mytree_node);

	return 0;
}

