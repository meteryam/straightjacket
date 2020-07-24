# -*- coding: utf-8 -*-

"""

GPL v3:

The straightjacket copiler translates code written in the straightjacket
programming language to c code.
Copyright (C) 2020 Jessica Richards

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


"""

import sys

def my_error_message(message,line_number,filename,input_line):

	if input_line != '':
		print message + str(line_number) + ' of file \"' + filename + '\":'
		print '>> ' + input_line.rstrip()
		sys.exit('Aborting compilation.')
	else:
		sys.exit(message + str(line_number) + ' of file \"' + filename + '\".  Aborting compilation.')




def tokenizer(input_string):
	
	# exclude single-line comments
	# break up the input string into tokens
	# each nested group of parentheses should be a token
	# each nested group of curly braces should be a token, as long as it isn't enclosed by parentheses
	# each quoted string should be a token, as long as it isn't enclosed by either parentheses or curly braces
	# other tokens are broken up by whitespace
	# to ensure case-insensitivity, every character outside of a quoted string should be forced to lowercase
	# detect and exclude multi-line comments

	mode = 'append'
	count = 0
	numparens = 0
	numbraces = 0
	working_str = ''
	working_array = []
	quoted = False
	
	for char in input_string:
		
		if count == 0:
			prevchar = ''
		else:
			prevchar = input_string[count]
		
		
		# handle single-line comments

		if (count + 1 < len(input_string)):
			nextchar = input_string[count+1]
		else:
			nextchar = ''

		if (char == '/') and (nextchar == '/') and (prevchar != '\\'):
			break
		
		# build token

		if mode == 'append':
			if (char == '(') and (prevchar != '\\'):
				if working_str != '':
					working_array.append(working_str)
				mode = 'paren_token'
				numparens = numparens + 1
				working_str = char
			elif (char == '{') and (prevchar != '\\'):
				if working_str != '':
					working_array.append(working_str)
				mode = 'brace_token'
				numbraces = numbraces + 1
				working_str = char
			elif (char == '`') and (prevchar != '\\'):
				if working_str != '':
					working_array.append(working_str)
				mode = 'quote_token'
				working_str = char
			elif (char == ' ') and (prevchar != ' ') and (prevchar != '\\') and (working_str != ''):
				working_array.append(working_str)
				working_str = ''
			elif (char == '\t') and (prevchar != '\t') and (prevchar != '\\') and (working_str != ''):
				working_array.append(working_str)
				working_str = ''
			else:
				if quoted == False:
					#char.lower()
					if ( char == '`' ) and (prevchar != '\\'):
						quoted = True
						working_str = working_str + char
					elif not ((char == ' ') and (prevchar == ' ')) and not ((char == '\t') and (prevchar == '\t')):
						working_str = working_str + char.lower()
					elif (char == ' ') and (prevchar != '\\') and (working_str != ''):
						working_array.append(working_str)
						working_str = ''
					else:
						working_str = working_str + char.lower()
					if ( count == len(input_string) - 1 ):
						working_array.append(working_str)
				elif ( quoted == True ):
					if ( char == '`' ) and (prevchar != '\\'):
						quoted = False
					working_str = working_str + char
					


		# build tokens surrounded by parentheses
		# these will be used for conditionals, expressions and subroutine calls
		
		elif mode == 'paren_token':
			if (char == '(') and (prevchar != '\\'):
				numparens = numparens + 1
				working_str = working_str + char
			elif (char == ')') and (prevchar != '\\'):
				numparens = numparens - 1
				working_str = working_str + char
				if ( numparens == 0 ):
					mode = 'append'
					working_array.append(working_str)
					working_str = ''
					#print 'here i am'
			else:
				if quoted == False:
					#char.lower()
					if ( char == '`' ) and (prevchar != '\\'):
						quoted = True
					working_str = working_str + char.lower()
				elif ( quoted == True ):
					if ( char == '`' ) and (prevchar != '\\'):
						quoted = False
					working_str = working_str + char

		# build tokens surrounded by curly braces that aren't embedded within parentheses
		# these will be used for list literals
				
		elif mode == 'brace_token':
			if (char == '{') and (prevchar != '\\'):
				numbraces = numbraces + 1
				working_str = working_str + char
			elif (char == '}') and (prevchar != '\\'):
				numbraces = numbraces - 1
				working_str = working_str + char
				if ( numbraces == 0 ):
					mode = 'append'
					working_array.append(working_str)
					working_str = ''
			else:
				if quoted == False:
					#char.lower()
					if ( char == '`' ) and (prevchar != '\\'):
						quoted = True
					working_str = working_str + char.lower()
				elif ( quoted == True ):
					if ( char == '`' ) and (prevchar != '\\'):
						quoted = False
					working_str = working_str + char

		# build quoted strings that aren't surrounded by curly braces or parentheses
		# these will be used for programmer-defined literals with the "quoted" option enabled
				
		elif mode == 'quote_token':
			if (char == '`') and (prevchar != '\\'):
				mode = 'append'
				working_array.append(working_str)
				working_str = ''
			else:
				working_str = working_str + char
		
		count = count + 1
		
	# when multi-line comments are encountered, remove commented tokens
		
	count = 0
	final = len(working_array) - 1
	countdown = 0
	foundEnd = False
	
	for entry in working_array:
		if entry == "=begin":
			rangecount = final
			while True:
				countdown = countdown - 1
				if countdown < count:
					break
				else:
					del working_array[rangecount]
			#scope_handler('comment_begin','')
		elif entry == "=end":
			foundEnd = True
			rangecount = 0
			while True:
				del working_array[rangecount]
				countdown = countdown + 1
				if countdown >= count:
					break
			#scope_handler('comment_end','')
			
		count = count + 1

	return working_array

# end tokenizer


"""

def scope_handler(type,name):

	if type == 'comment_begin':
		return [type,name]
	#elif type == 'comment_end':
		#if len(myglobals.current_context) == 0:
			#sys.exit('Incorrect context provided on line ' + line_number + 'of file \"' + open_file + '\".')
		#elif (len(myglobals.current_context) > 0) and (myglobals.current_context[-1][0] != 'comment_begin'):
			#sys.exit('Incorrect context provided on line ' + line_number + 'of file \"' + open_file + '\".  Current context is \"' + myglobals.current_context[-1][0] + '\".')
			



	if comment
		# modify current context
	else module
		if import & not in input files
			add file and module name to list of input files

			# only one "main" module can exist in a single program
			# if external "main" modules are imported, they must be aliased
			# all identifiers share the same namespace
		end if
		if current_file != open_file
			close current file
			change current file to new file
			open new file
			mode = "begin"
		else
			change current file to new file
	else function
		# modify current context
	else procedure
		# if enclosing context is a function, throw error and exit
		# modify current context
	else if_condition
		# modify current context
	else loop_label
		# modify current context
	else end function
		# destroy variables that pass out of scope, unless the function is recursive
		# write goto label
		# write closing brace
		# mode = definitions
	else end procedure
		# destroy variables that pass out of scope
		# write goto label
		# write closing brace
		# mode = definitions
	else end if_condition
		# strip condition from current scope
		# strip label from current scope
		# write closing brace
		# clean up temporary list variables
	else end loop_label
		# strip label from current scope
		# write closing brace
	else abort

# end scope_handler

"""


"""

:identifier_validator

	# first character:  $ or @ or # or _ or :unicode_letters: or :num:
	
	# middle characters:  - or _ or :unicode_letters: or :num:
	
	# last character:  _ or :unicode_letters: or :num:
	
	
end identifier_validator


:declare_subroutine

	# declare [foreign] returnType function : [argType] [argType]
	# declare [foreign] procedure : [argType] [argType]
	
	# declare whether a subroutine is a function or a procedure or an operator
			# operators can only be defined within the context of a type
	# declare the types of a subroutine's arguments
	# declare the type of a subroutine's return (unless it's a procedure)
	# exporting subroutines
	# can replace variables with expressions to enforce runtime assertions
	# all identifiers share the same namespace
	
end declare_subroutine


:struct_declaration_handler

	# variable declarations
			declare (export) (const) int : myType (= 5)
		or
			declare type (export) (const) struct : typename (= 5, 2, 1.5)
			
			# the keyword "type" makes the definition a type rather than an instance.  in this case, the type name would be declared, rather than the variable name

	# type declarations

	# simple structs:  declare type (export) structName as int (= 5)
			# structs with only one field can be treated as if they weren't structs
			# can (optionally) be addressed without mentioning their fields
			# field names must be globally unique
			
	# tuple structs: 
			declare type (export) struct structName
				operator + is myfunC(structName,structName)
				operator ++ is myfunD(structName)
				myfunA(structName -> structNameA)	# defines a type conversion function
				no_arithmetic			# prohibits the use of built-in arithmetic operators
			begin
				int (= 0)																								# extends type "int"
				float : myFloat :i (= 1.2)																# creates suffix "i"
				int : myInt (= 0) enum { FALSE = 0, TRUE = 1 }				# enum section creates values
				[0..1]int : myInt (= 0) enum { FALSE = 0, TRUE = 1 }		# range prefix limits allowed range
				const int : letter_a (=97) quoted_enum { a = 97 }		# enumerated values must be quoted
				myfunC(myInt) (: myInt2) (= myfunC(0))						# uses a user-defined range function
			end struct
			
			# user-defined types can extend other types, as long as each field's label is unique
			# can tag fields with single-character affixes to allow simultaneously adding different types to the same variable in a safe way (eg 1 + 1i)
			# affixes can use any printable unicode character
			# can assign aliases to enumerated values
			# literals can be marked with the quoted keyword
			# types can be exported to other modules at declaration time
			# allow calls to user-defined functions for custom conversions, operators and type validity/restriction checks
				# allow operator overloading
				# the characters ! and * can be operators
			# exported variables are exported as read-only objects by default; must use "mutable" keyword to make exported variables mutable


	# fields
		# if no fieldname is given, the name of the field defaults to the type
		# unpacked
		# signed and unsigned (eg int32+)
		# different lengths (eg int32)
		# support both signed and unsigned zeroes (better for complex arithmetic)
		# support hexadecimal literals (better floating point precision)
		# the default initialization value is zero
	
		# integers
			# default to the width closest to 32 bits
				
		# floating-point numbers
			# IEEE 754 floating point standard
			# variables default to the natural bit width of the machine
			# constants default to the widest available bit width of the machine
			
		# use alloca to guarantee stack allocation for structs that don't contain lists
		# use malloc to guarantee heap allocation for structs that do contain lists
	
	# operations on fields
	
	# dot notation for fields (eg mystruct.fieldname)
	
	if expression
		# call expression_handler
	else abort
	
end struct_declaration_handler
	
:list_declaration_handler

	# declare (type) (export) (const) list : listName (= { 1, 2})

	# format:  8-bit type, 8-bit exponent, structs, pointer to previous entry, pointer to next entry
			# reserved type numbers:  int, float, pointer to list
			# other type numbers are assigned at compile time
			# bit width = 2^exponent
			# pointer either points to null or to the next cons
	# if the entire list is declared with a specific type, then runtime type checking is suppressed
	# the zeroth value is null. this is the default initialization of an empty list.
	# structs are always inlined
	# use curly braces instead of parentheses (they line up better when arranged vertically)
	# the default initialization value is the empty list
	# circular list declaration:  listname = { listname }
	# use malloc to keep list elements in the heap
	

end list_declaration_handler

:variable_declaration_handler

	# struct declarations
		# if simple struct declaration
		
			# call struct_declaration_handler(simple)
		
		# if tuple declaration
		
			# call struct_declaration_handler(tuple)
			
	# list declarations
		
		# call expression_handler

	# public variables
	# strong, static type checking
			# different names represent different types
			# structs with fields that have the same names and the same underlying types in the same order have the same types
			# extended types are compatible with the types they extend
			# throw warnings when converting a number or type to a type that cannot contain it
	# constants cannot be null, except for the reserved constant "null"
	# automatic initialization
	# all identifiers share the same namespace

end variable_declaration_handler

:expression_handler

	# the equal sign should appear on the right-hand side of the expression
		# this makes more sense for pipelining

	# optionally support the struct's field syntax to declare a number's type
	
	# general details
		# compare/match fields and values by their names and base types
		# quoted values
		# suffixes
		# enumerated values
		# user-defined conversion functions
		# user-defined range functions
		# parentheses group terms
		# software transactional memory used when updating values external to a procedure marked "atomic"

	# operators
			# strict order of operations
				# parentheses
				# function calls
				# exponents
				# multiplication, division
				# addition, subtraction

				* alternate operations with equal priority, in ascending magnitudes, to reduce the chances of exceeding numeric ranges

			# lazy evaluation
			# operate on fields and values by their names and base types.  ignore field order.
			# operators
				# use single spaces around operators
				# user-defined operators

	# numbers
		# arithmetic operators:  + - * / ÷ **

		# integers
			# automatic checking for range overflows
			# automatic integer zero division checks
			# mod operator

		# floating-point numbers
			# prevent overflows from turning into infinities
			# IEEE 754 floating point standard
			# raise exceptions for unchecked NAN and INF values
			# consistent and minimal rounding rules
			# use the kahan summation algorithm for arithmetic

	# lists
		# concatenation operator:  &
			# cannot be mixed with arithmetic operations
		# reserved constant "null"
		# list literal:  { 1 2 3 }
			# call list_declaration_handler
		# list element:  list[5][2]
			# must be null-checked
		# last list element:  list[$]
		# next-to-last list element:  list[$-1]
			# automatically check for null
		# remove list element:  list[1].pop
			# automatically check for null
		# list slice:  list[1..3]
			# automatically check for null

	# function calls
		# pass structs that don't contain lists by value to improve thread safety
		# pass everything else by reference to improve performance
		# function calls can be passed as variables
		# function calls can be piped
			# f | g						# pipe operator is implied to connect return to single input
			# f | g ( x, 1> )		# pipe operator connects return to second input

end expression_handler

:define_subroutines

	# subroutines
			# use "define" keyword
			# scope-based heap deallocation

	# function definitions
			# cannot access global  variables
			# cannot modify argument variables
			# cannot call procedures
			# return statements
					# the return statement is part of the end statement:  return x end foo
			# arguments and declarations can use generic types (number, atom, list, struct, container), but their arguments are restricted.  generic functions are implemented as templates, which are then used to generate type-specific functions each time they're called.
			# cofunction statement:  implements coroutines (only one statement allowed per function)
					# control passed via guarded "continue" statements
					# implemented with goto statements
			# tail call elimination

	# procedure definitions
			# procedures in modules other than "main" must be exported
			# don't compile private procedures in modules other than "main"
			# prohibit recursive procedure calls
			# use keyword "atomic" to enforce software transactional memory for side effects (good for thread safety)
			# foreign functions are compiled separately, and might be impure
					# marked with the "unsafe" keyword

end define_subroutines

:define_exceptions

	# implemented as procedures
			# first caught in the current scope
			# then caught in the supervisor scope (if present); enables erlang's "let it crash" philosophy of multithreading
	# automatically insert checks that can call them
	# have the same restrictions as their enclosing scopes
	# if uncaught by the current module, can only be caught by the main module
		# can catch exceptions categorically, or by module
	# all identifiers share the same namespace

end define_exceptions

:exception_catcher

	# catch [module.][subroutine.]exception_name

	# both module and subroutine names are always optional
	# subroutines can catch their own exceptions; this supports defensive programming
	# the main module can catch uncaught exceptions from any module; this supports the supervisor model of thread handling
		
end exception_catcher

:if_handler

	# if condition
		# if condition begin  [blockname]
		# else condition
	# numeric conditions:  < <= ≤ > >= ≥ = != ≠
	# logical conditions:  AND, OR, XOR, NOT
			# precedence:  not -> and -> or, xor
	# support integer strings in conditionals (i.e. snobol pattern matching) for lists
			# represented as either structs of integers or lists of structs of integers
					# literals for user-defined integer types must use the proper syntax (eg quoted vs unquoted)
			# use logical operators to separate arguments
			# use & as a concatenation operator
			# allow logical operators OR, XOR and NOT in appended strings
			# use curly braces to nest conditions
	# references to list elements must be checked for null
	# emit "if" or "else if" code

end if_handler

"""