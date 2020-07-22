#!/usr/bin/python

# -*- coding: utf-8 -*-

"""
This program implements the reference version of the Straightjacket compiler.

The straightjacket language is intended to be small, safe and easy to read.  It will include support for primitive lists, pattern matching, generics and type extension.  I try to make no assumptions about how many threads a program might use, so as to increase the thread safety of straightjacket programs.

Straightjacket programs are composed of one or more modules, one of which must be named "main".  Each module may contain zero or more functions (which must not have side effects) or procedures (which should have side effects).  Functions and procedures may be private (the default) or they may be exported for use by other modules.  Exported resources must be imported explicitly in order to be used by other modules, and they must always explicitly refer to the module from whence they came.

The main module also contains a "body", which is the equivalent of the "main function" in c-like languages.  The main module can also catch exceptions that aren't caught by the subroutines from which they've arisen.  Subroutines defined within the main module and called from it must use forward declarations.

Control flow structures include:

loop begin [blockname]
	...
	break
	...
end loop  [blockname]


loop each [range or list] [with varname] begin [blockname]
	...
end loop [blockname]


if (condition) begin [blockname]
	...
else (condition)
	...
else
	...
[end if [blockname]] or [else abort [blockname]]

The "else abort" option more directly supports dijkstra's structured programming paradigm.  The end if option is offered because that approach might not fit every problem.

Straightjacket has five built-in data types:

- list
- struct
- int
- float
- number

Every variable is either a list or a struct, and every element of a list or struct is either an int or a float.  The type "number" is reserved for the arguments and local variables of generic functions, which can then be applied to either ints or floats.

Lists and structs that contain lists are stored on the heap, and are automatically reclaimed when they go out of scope.  A function's local variables only go out of scope when it returns a value.  All other structs go on the stack.

Straightjacket natively supports a primitive form of literate programming...

The nity-gritty:

- Most tokens share the same namespace.  Modules, subroutines, operators, variables, constants, block labels, type names.  Struct fields can use types from this shared namespace, but they don't have to.
- Most tokens have a rather liberal format:  [$|@|#] + [_|-|:alpha:|:num:] + [_|:alpha:|:num:]
- Tokens must be separated from everything else by whitespace.
- The equal sign must appear on the right-hand side of expressions.
- The equal sign is used for both equality and assignment.  This eliminates a common source of errors when programmers accidentally use the assignment operator in a comparison context.
- Straightjacket is case-insensitive.  These strings represent the same tokens:  hello HeLlo hELLo
- The logical operators are:  AND, OR, XOR, NOT
- To facilitate pattern matching, list literals in if conditions may include logical operators (except for the AND operator).
- The custom data type syntax is extremely flexible.  This is intended to facilitate (among other things) easier construction of strings, complex numbers, booleans and matrices.
- References to specific list positions (except for constant lists) must be wrapped in explicit null checks.
- The compiler inserts automatic checks for range overflows, zero division of integers, infinities, NaNs, list ranges, etc.  These may be caught either by the subroutine within which they arise, or by the main module.
- Functions are pure (i.e. they cannot have side effects).  However, procedures can have side effects.  This makes both correct coding and troubleshooting easier.
- Software transactional memory must be used to update lists when subroutines are marked "atomic".  This can be done at either definition time or at call time.  This facilitates multi-threaded programming without unduly burdening single-threaded programs.
- Type checking is both strict and static.  Two structs have the same type if their fields have the same names, same underlying types and are in the same order.

"""

import sys, getopt

import content #,content_lit

module_list = []
token_list = []
token_list_truncated = []
conversion_list = []
argument_list = []
current_module_entry = []

multi_line_comment = False
no_truncate = True
variable_declaration = False
procedure_call = False
expression = False
end_module_statement = False
is_file_literate = False

working_file=""
open_file = ""
mode = "collect"
current_file = ""



# handle arguments

argument_list = sys.argv
del argument_list[0]
#print argument_list

if len(argument_list) == 1:
	module_list.append(['main', 'main', 'nonliterate', argument_list[0]])
elif (len(argument_list) == 2) and (argument_list[0] == '-l'):
	module_list.append(['main', 'main', 'literate', argument_list[1]])
else:
	sys.exit("Wrong number of arguments supplied.  Exiting.")


# loop through all of the input modules

while True:
#for current_file in reversed(module_list):
	
	current_module_entry = module_list[-1]
	#current_file = 
	
	#print current_file
	#sys.exit()
	
	# extract contents of literate documents
	
	if current_module_entry[2] == "literate":
		nop=1
		is_file_literate = True
		# working_file = literate_handler(current_module_entry[3])
	else:
		is_file_literate = False
		working_file = current_module_entry[3]
	
	# process straightjacket code
	
	# content.scope_handler(current_file)
	
	count = 0
	open_file=open(working_file)
	for line in open_file:
	
		token_list = content.tokenizer(line.rstrip())
		
		print token_list
		
		if is_file_literate == True:
			line_number = token_list.pop[0]
		else:
			count = count + 1
			line_number = count
		
		variable_declaration = False
		procedure_call = False
		expression = False
		
		# if variable declaration:  token_list[0] == "declare", no token equals ":"
			# variable_declaration = True
		# elif procedure_call (must have matching parentheses and no equal sign)
			# procedure_call = True
		# elif expression (the next-to-last token must be an equal sign)
			# expression = True
			
		#if not token_list[0] == "":
		
			#if mode == "collect":
				
				# if (token_list[0] == "import") or (token_list[0] == "limport")
					# ignore duplicates
					# if token_list[0] == "limport"
						# call literate_handler
						# set modulepath to literate_handler_output
					# else
						# set filename to token_list[1]
					# content.scope_handler(module,modulepath,aliasname)
					# close(open_file)
					# break
			
				# look for two words:  module modulename
					# the module name must be "main" and must be the first module
					# if all conditions met
						# content.context_handler(token_list[1],current_file)
						# mode = "declare"
				# else four words:  module modulename definitions begin
					# the module name must not be "main" and must not be the first module
					# if all conditions met
						# mode = "define"
				# else throw an error and exit
			
			#elif variable_declaration == True:
				
				# variable declarations can appear anywhere except before the beginning of the module
				
				# call variable_declaration_handler
				
			
			#elif mode == "declare":
				
				# if forward_declaration
					# call declare_subroutine
				
				# if (token_list[0] == "begin") and (current module == "main"):
					# mode = "body"
				# else
					# found illegal statement in the declaration section
				
			#elif (mode == "body") or (mode == "definitions_body"):
				
				# if token_list[0] == "abort":
					# emit abort code
					
				# elif (token_list[0] == "loop") and (token_list[1] == "begin"):
					# if token_list[2] exists, call scope_handler
					# emit while loop code
					
				# elif  (token_list[0] == "break"):
					# emit break statement code
					
				# elif (token_list[0] == "loop") and (token_list[1] == "each"):
				
					# loop each <list or range> (with varname) begin [loopname]
				
					# if last token entry isn't begin, let loop label
					# if (token_list[3] == "with") and (token_list[5] == "begin"):
						# set loop variable to token_list[4]
					# elif (token_list[3] == "begin"):
						# auto-generate loop variable
					# emit for loop code
					
				# elif (token_list[0] == "if") or ((token_list[0] == "else") and (number of tokens > 1):
				
					# cope with multiple conditions
					# cope with if block labels
					# cope with if guards
					# call if_handler
					
				# elif token_list[0] == "else":
					# emit else code
					
				# elif procedure_call == True:
					# call scope_handler
					# emit procedure call code
						# pass structs that don't contain lists by value to improve thread safety
						# pass everything else by reference to improve performance
						
				# elif expression == True:
					# call expression_handler
					
				# elif (token_list[0] == "convert") and (token_list[2] == "convert"):
					# syntax:  convert myvar to type_name
					# pull conversion details from conversion_list
					# emit type conversion code
					# throw warnings when downshifting types that might cause problems
					
				# elif token_list[0] == "end":
					# if token_list[2] exists, block_label = token_list[2]
					# else block_label = ""
					# call scope_handler(end,token_list[1],block_label)
					
				# elif (token_list[0] == "definitions") and (token_list[1] == "begin"):
					# if enclosed within a subroutine, throw an error and exit
					# mode = "definitions"
					
				# else
					# found illegal statement in the body of the module
			
			#elif mode == "definitions":
			
				# if token_list[0] == "define":
					# mode = "definitions_body"
					# if function_definition, call define_subroutines(function)
					# elif procedure_definition, call define_subroutines(procedure)
					# elif exception_definition, call define_exceptions
				
				# elif token_list[0] == "catch":
					# mode = "definitions_body"
					# catch [module.][subroutine.]exception_name
					# call exception_catcher
					
				# else (token_list[0] = "end") and (token_list[1] = "module"):
					# end_module_statement = True
					# if token_list[2] exists, block_label = token_list[2]
					# else block_label = ""
					# call scope_handler(end,token_list[1],block_label)
					
				# else
					# found illegal statement in the definitions section


	# wind back through all of the modules we've added in reverse order
	# stop looping when we reach the end of the first module

	else:
		if len(module_list) == 1:
			break
		else:
			del module_list[-1]


	

