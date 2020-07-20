
#include <stdio.h>


struct _exception_node
{
	uint16_t exitcode;
	uint8_t *ptr;
};


void myfunc(int *restrict myarg, struct _exception_node **_exception)
{
	struct _exception_node *_tmpexception = (struct _exception_node *)calloc(sizeof(struct _exception_node));

	myfunc_begin:

	*myarg = 1;

	if (*myarg == 1) {
		goto myfunc_myexception;
	}


	goto myfunc_end;

	myfunc_myexception:

	_tmpexception -> exitcode = 1;
	_tmpexception -> ptr = (uint8_t *)malloc(sizeof("MY_EXCEPTION\n"));
	_tmpexception -> ptr = "MY_EXCEPTION\n";
	*_exception = _tmpexception;
	goto myfunc_end;

	myfunc_end:

	return;
}

void foo(int *restrict myarg, struct _exception_node **_exception)
{
	myfunc(myarg, _exception);
}

uint16_t main(void)
{
	struct _exception_node *_exceptionlist = 0;

	int someint = 0;
	int* ptr_to_int = &someint;
	int* ptr2 = ptr_to_int;

//	myfunc(ptr2, &_exceptionlist);
	foo(ptr2, &_exceptionlist);

	if (_exceptionlist != 0) {
		goto main_myexception;
	}

	printf("%d", someint);		printf("\n");

	goto main_end;

	main_myexception:
	fprintf(stderr, _exceptionlist -> ptr);
	exit(_exceptionlist -> exitcode);

	main_end:

	return 0;
}