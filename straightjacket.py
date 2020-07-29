#!/usr/bin/python

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

import sys, getopt

import content

module_list = []			# this keeps track of all of our modules
module_tree = []		# this keeps track of the chain of modules from main to the current module we're processing
allowed_module_calls = []			# this keeps track of the modules that have been imported into the current module
token_list = []
token_list_truncated = []
conversion_list = []
argument_list = []
current_module_entry = []
current_context = []
declared_variables = []

reserved_words = ['abort', 'and', 'array', 'begin', 'cimport', 'declare', 'definitions', 'else', 'end', 'enum', 'export', 'float', 'foreign', 'function', 'if', 'import', 'int', 'limport', 'list', 'loop', 'main', 'mod', 'module', 'not', 'operator', 'or', 'procedure', 'quoted_enum', 'struct', 'type', 'xor']

types = []

multi_line_comment = False
variable_declaration = False
procedure_call = False
expression = False
end_module_statement = False
is_file_literate = False

working_file=""
open_file = ""
current_file = ""
line_number = ""
mode = "collect"

# handle arguments

argument_list = sys.argv
del argument_list[0]

if len(argument_list) == 1:
	module_list.append(['main', 'nonliterate', argument_list[0]])
	module_tree.append(['main', 'nonliterate', argument_list[0]])
elif (len(argument_list) == 2) and (argument_list[0] == '-l'):
	module_list.append(['main', 'literate', argument_list[1]])
	module_tree.append(['main', 'nonliterate', argument_list[0]])
else:
	sys.exit("Wrong number of arguments supplied.  Exiting.")


# loop through all of the input modules

while True:
	
	#print module_tree
	
	current_module_entry = module_tree[-1]
	
	#print current_module_entry
	
	# extract contents of literate documents
	
	if current_module_entry[1] == "literate":
		is_file_literate = True
		# working_file = literate_handler(current_module_entry[3])
	else:
		is_file_literate = False
		working_file = current_module_entry[2]
	
	# process straightjacket code
	
	count = 0
	open_file=open(working_file)
	for line in open_file:
	
		token_list = content.tokenizer(line.rstrip())
		
		# handle multi-line comments
		
		if (len(token_list) > 0) and (token_list[-1] == '=begin'):
			current_context.append(['comment_begin','',''])
			del token_list[-1]
		elif (len(token_list) > 0) and (token_list[0] == '=end'):
			del current_context[-1]
			del token_list[0]
		elif (len(current_context) > 0) and (current_context[-1][0] == 'comment_begin'):
			token_list = []
		
		if len(token_list) > 0:
			print token_list
		
		if is_file_literate == True:
			line_number = token_list.pop[0]
		else:
			count = count + 1
			line_number = count
		
		variable_declaration = False
		procedure_call = False
		expression = False
		
		# detect a few common conditions
	
		if len(token_list) > 0:
			
			
			# to do:  better error-checking on declarations
			# also stop on colons
			
			if (token_list[0] != 'declare') and (len(token_list[0]) > 1):
				variable_declaration = True
				for i in token_list:
					if (i == 'type') or (i == 'function') or (i == 'procedure'):
						variable_declaration = False
						break

			elif (len(token_list[0]) == 2) and (token_list[-1][0] == '(') and (token_list[-1][-1] == ')'):
				procedure_call = True
				
			elif (token_list[0] != 'declare') and (len(token_list[0]) > 1) and (token_list[-2] == '='):
				expression = True
		
			if mode == "collect":
				
				if (len(token_list) == 4) and ((token_list[0] == "import") or (token_list[0] == "limport")):
					
					#if (token_list[1] != "foreign"):
						
						
					# fill local module_list with duplicates
					# allowed_module_calls
					# this allows us to verify that module calls are correct
					
					# literate module imports
					if token_list[0] == "limport":
						# call literate_handler
						# set modulepath to literate_handler_output
						nop = 1
						
					# regular module imports
					else:
						tmpstr = ''
						#print token_list[1]
						if (token_list[1][0] == '`') and (token_list[1][-1] == '`'):
							
							# strip off the backticks
							count = 0
							for i in token_list[1]:
								if (count != 0) and (count != len(token_list[1]) - 1):
									tmpstr = tmpstr + token_list[1][count]
								count = count + 1

							modulepath = tmpstr

						else:
							content.my_error_message('There is an unquoted module path',line_number,working_file,line)
						
					# if the module has already been added to current_context, then it doesn't need to be processed and we can add it to the allowed_module_calls list
					# the allowed_module_calls list allows us to verify that calls to external modules are correct
					
					if (token_list[3] == 'main') or (modulepath == module_list[0][2]):
						content.my_error_message('There is an import statement referring to the main module',line_number,working_file,line)
						
					# to do:  error-check module path imports and alias consistency
					
					duplicate = False
					for module_entry in module_list:
						if module_entry[0] == token_list[3]:
							#print 'here i am'
							duplicate = True
							duplicate_allowed = False
							for allowed_entry in allowed_module_calls:
								if allowed_entry[1] == token_list[3]:
									duplicate_allowed = True
							if duplicate_allowed == False:
								allowed_module_calls.append(['module',token_list[3],''])
							break
						
						
					#print duplicate
					#exit()
						
					# if the module hasn't already been added to the module list, and to the module tree, then we need to close the current module and open that module
					
					if duplicate == False:
						current_context = []
						allowed_module_calls = []
						
						current_context.append(['module',token_list[3],''])
						module_list.append([token_list[3], 'nonliterate', modulepath])
						module_tree.append([token_list[3], 'nonliterate', modulepath])
						
						open_file.close()
						break
						
				# importing c files
				elif  (len(token_list) == 4) and (token_list[0] == "cimport"):
					# to be implemented later
					nop = 1
			
				elif (len(token_list) == 2) and (token_list[0] == "module") and (token_list[1] == 'main'):
					
					if (len(module_tree) != 1) or (module_tree[-1][0] != 'main') or (module_tree[-1][2] != module_list[0][2]):
						content.my_error_message('Only the first module can be designated \"main\", but there is a statement referring to the current module as \"main\"',line_number,working_file,line)
					else:
						mode = 'declare'
						
				elif (len(token_list) == 4) and (token_list[0] == "module") and (token_list[2] == 'definitions') and (token_list[2] == 'begin'):
					
					if (len(module_tree) == 1) or (module_tree[-1][0] == 'main') or (module_tree[-1][2] == module_list[0][2]):
						content.my_error_message('The main module must contain a body, but the \"module\" statement ends with \"definitions begin\"',line_number,working_file,line)
					else:
						mode = 'define'
				else:
					content.my_error_message('There is an unrecognized statement',line_number,working_file,line)
			
			elif variable_declaration == True:
				
				# variable declarations can appear in any module section except before the beginning of the module
				# to do:  prohibit within control flow structures
				
				# if next-to last entry is equal sign and none of the words are array, struct or list
				# handle integer types:  
				
				#	8			signed char, unsigned char
				#	16		signed short, unsigned short
				#	32		signed long, unsigned long
				#	64		signed long long, unsigned long long
				
				# reserved_words list
				# types list
					# class, typename, value, numeric, export, const, range, suffix, binding functions, enumerations, quoted enumerations
					# classes:  primitive, array, struct, list
				# declared_variables list
					# primitives:  path, primitive, typename, value
					# arrays:  path, array, typename, length
					# structs:  path, struct, [typename, length, value]
					# lists:  path, list, typename, circular
				
				# declare (export) (const) typename variablename = value
				
					# signed long variablename = value;
					
					# 8 -> char
					# 16 -> short
					# 32 -> long
					# 64 -> long long
					# + -> unsigned
					# int -> signed long
				
				# declare (export) (const) typename array variablename[2]
				
					# implement as dynamic pascal-style arrays
				
				# declare (export) (const) struct variablename begin
					# typename = value
					# typename = value
				# end variablename
				
				# declare (export) (const) (typename) list variablename (= variablename)
				
			
			# elif mode == "declare":
				
				# if forward_declaration
					# call declare_subroutine
					
				# handle type declarations
				
				# if (token_list[0] == "begin") and (current module == "main"):
					# mode = "body"
				# else
					# found illegal statement in the declaration section
				
			# elif (mode == "body") or (mode == "definitions_body"):
				
				# if mode == definitions_body:
					# check current_context for subroutine enclosure
					# if not enclosed within a subroutine, throw an error and exit
				
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
					# cope with pattern matching for structs and lists
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
					
				# elif raise statement
					
				# else
					# found illegal statement in the body of the module
			
			# elif mode == "definitions":
			
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
					
					
			else:
				content.my_error_message('There is an unrecognized statement',line_number,working_file,line)


	# wind back through all of the modules we've added in reverse order
	# stop looping when we reach the end of the first module

	else:
		if len(module_tree) == 1:
			break
		else:
			del module_tree[-1]


	

