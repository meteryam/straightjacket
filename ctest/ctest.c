
#include <stdio.h>
#include <stdint.h>

struct _int08_node
{ 
	uint8_t data;
	uint64_t children;
	struct _int08_node **ptr;
};

struct _track_int08_node
{ 
	struct _track_int08_node *prev;
	struct _int08_node *node;
};

struct _exception_node
{
	uint32_t line_number;
	uint8_t *module_name;
	uint8_t *exception_name;
	uint16_t exitcode;
};

void createnode_int08(struct _int08_node **mytree, struct _int08_node **_mytree_node, struct _track_int08_node **_mytree_path, uint8_t bool, uint64_t m)
{

	struct _int08_node *_newnode;
	uint64_t n;

	n = m + 1;



	// create a node
	_newnode = (struct _int08_node *)calloc(sizeof(struct _int08_node));
	_newnode -> data = bool;



	// add the new node to the existing tree
	if (*_mytree_node == 0) {
		*mytree = _newnode;
		*_mytree_node = *mytree;
	} else if ((*_mytree_node) -> ptr == 0) {
		(*_mytree_node) -> ptr = (struct _int08_node **)calloc(n * sizeof(struct _int08_node*));
		(*_mytree_node) -> ptr[m] = _newnode;
		(*_mytree_node) -> children = n;
	} else {
		(*_mytree_node) -> ptr[m] = _newnode;
		(*_mytree_node) -> children = n;
	}

	return;
}

void walktree_int08(struct _int08_node **mytree, struct _int08_node **_mytree_node, struct _track_int08_node **_mytree_path, uint64_t m)
{

	struct _track_int08_node *_next_track_node;

	// add a new tracking node

	if (*_mytree_path == 0)
	{
		_next_track_node = (struct _track_int08_node *)malloc(sizeof(struct _track_int08_node));
		_next_track_node -> prev = *_mytree_path;
		_next_track_node -> node = *_mytree_node;
		*_mytree_path = _next_track_node;
	}

	// go to the next node

	*_mytree_node = (*_mytree_node) -> ptr[m];



	return;
}

void deletenode_int08(struct _int08_node **mytree, struct _int08_node **_mytree_node, struct _track_int08_node **_mytree_path)
{

	struct _int08_node *_newnode;
	struct _track_int08_node *_next_track_node;
	struct _int08_node **_newarray;
	uint64_t n;
	int64_t _i;
	uint64_t _tmpchildren;

	// set old node pointer to null

	if (*_mytree_path != 0)
	{
		_tmpchildren = (*_mytree_path) -> node -> children;

		for (_i = 0; _i < _tmpchildren; _i++)
		{
			if (*_mytree_node == (*_mytree_path) -> node -> ptr[_i])
			{
				(*_mytree_path) -> node -> ptr[_i] = 0;
			}
		}
	}

	// delete the current node

	if ((*_mytree_node) -> ptr != 0)
	{
		free((*_mytree_node) -> ptr);
	}
	free((*_mytree_node));

	*_mytree_node = (*_mytree_path) -> node;

	// remove most recent node from path

	_next_track_node = (*_mytree_path) -> prev;
	free((*_mytree_path));
	*_mytree_path = _next_track_node;

	// resize the next pointer array

	if (*_mytree_path != 0) {

		_tmpchildren = (*_mytree_path) -> node -> children;
		_tmpchildren = _tmpchildren - 1;

		_newarray = (struct _int08_node **)malloc(_tmpchildren * sizeof(struct _int08_node*));

		if (_tmpchildren == 0) {
			free((*_mytree_node) -> ptr);
			(*_mytree_node) -> ptr = 0;
		} else {

			_i = 0;
			for ( ; _i <= _tmpchildren; ) {
				if ((*_mytree_node) -> ptr[_i] != 0) {
					_newarray[_i] = (*_mytree_node) -> ptr[_i];
				}
				_i++;
			}

		}

	}


	return;
}

void deltree_int08(struct _int08_node **tree, struct _int08_node **tree_node, struct _track_int08_node **path)
{
	struct _int08_node *_comparenode;
	struct _track_int08_node *_next_track_node;

	uint64_t _tmpchildren;
	int64_t _i;

	*tree_node = *tree;


	if (*tree > 0)		// skip null-valued trees
	{
		for(;;)
		{
			_tmpchildren = (*tree_node) -> children;
	
			if (_tmpchildren > 0)
			{
				_tmpchildren = _tmpchildren - 1;
				_i = _tmpchildren;

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
					(*tree_node) -> children = 0;
				}


			} else {
				free(*tree_node);

				if (*path == 0) 				// found the tree root
				{
					*tree = 0;
					*tree_node = *tree;
					break;

				} else {

					_i = (*path) -> node -> children;
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


	*tree = 0;
	*tree_node = 0;
	*path = 0;

	return;
}



uint16_t main(void)
{

	struct _int08_node *mytree = 0;
	struct _int08_node *_mytree_node;

	struct _track_int08_node *_mytree_path = 0;
	struct _track_int08_node *_next_track_node;

	struct _exception_node *_exception;
	
	uint8_t bool;
	uint64_t n;
	uint64_t m;
	int64_t _i;

	_mytree_node = mytree;

//	printf("%llu", UINT64_MAX);	printf("\n");

	bool = 1;
	m = 0;
	n = m + 1;

	if (m <= UINT64_MAX - 1)
	{
		createnode_int08(&mytree, &_mytree_node, &_mytree_path, bool, m);
	} else {
		_exception = (struct _exception_node *)malloc(sizeof(struct _exception_node));
		(_exception) -> line_number = 23;
		(_exception) -> module_name = "main.\n";
		(_exception) -> exception_name = "NODECOUNT_ERROR\n";
		(_exception) -> exitcode = 1;
//		goto NODECOUNT_ERROR;
	}

	bool = 0;
	m = 0;
	n = m + 1;

	if (m <= UINT64_MAX - 1)
	{
		createnode_int08(&mytree, &_mytree_node, &_mytree_path, bool, m);
	} else {
		_exception = (struct _exception_node *)malloc(sizeof(struct _exception_node));
		(_exception) -> line_number = 23;
		(_exception) -> module_name = "main.\n";
		(_exception) -> exception_name = "NODECOUNT_ERROR\n";
		(_exception) -> exitcode = 1;
//		goto NODECOUNT_ERROR;
	}

	// walk down the tree one node

	walktree_int08(&mytree, &_mytree_node, &_mytree_path, m);


	// go to the last node pointer

//	_i = _mytree_node -> children;
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

	deletenode_int08(&mytree, &_mytree_node, &_mytree_path);

//	deltree_int08(&mytree, &_mytree_node, &_mytree_path);

	printf("%d", _mytree_node -> data);		printf("\n");

	return 0;
}

