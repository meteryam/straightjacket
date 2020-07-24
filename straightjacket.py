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

module_list = []
token_list = []
token_list_truncated = []
conversion_list = []
argument_list = []
current_module_entry = []
current_context = []

multi_line_comment = False
variable_declaration = False
procedure_call = False
expression = False
end_module_statement = False
is_file_literate = False

working_file=""
open_file = ""
mode = "collect"
current_file = ""
line_number = ""


# handle arguments

argument_list = sys.argv
del argument_list[0]

if len(argument_list) == 1:
	module_list.append(['main', 'main', 'nonliterate', argument_list[0]])
elif (len(argument_list) == 2) and (argument_list[0] == '-l'):
	module_list.append(['main', 'main', 'literate', argument_list[1]])
else:
	sys.exit("Wrong number of arguments supplied.  Exiting.")


# loop through all of the input modules

while True:
	
	current_module_entry = module_list[-1]
	
	# extract contents of literate documents
	
	if current_module_entry[2] == "literate":
		is_file_literate = True
		# working_file = literate_handler(current_module_entry[3])
	else:
		is_file_literate = False
		working_file = current_module_entry[3]
	
	# process straightjacket code
	
	count = 0
	open_file=open(working_file)
	for line in open_file:
	
		token_list = content.tokenizer(line.rstrip())
		
		# handle multi-line comments
		
		if (len(token_list) > 0) and (token_list[-1] == '=begin'):
			current_context.append(['comment_begin',''])
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
	
		if len(token_list[0]) > 0:
			
			if (token_list[0] != 'declare') and (len(token_list[0]) > 1):
				variable_declaration = True
				for i in token_list:
					if (i == 'type') or (i == 'function') or (i == 'procedure'):
						variable_declaration = False

			elif (len(token_list[0]) == 2) and (token_list[-1][0] == '(') and (token_list[-1][-1] == ')'):
				procedure_call = True
				
			elif (token_list[0] != 'declare') and (len(token_list[0]) > 1) and (token_list[-2] == '='):
				expression = True
		
			if mode == "collect":
				
				if ((token_list[0] == "import") or (token_list[0] == "limport")) and (len(token_list) >= 4):
					if (token_list[1] != "foreign"):
						# fill local module_list with duplicates
						# this allows us to verify that module calls are correct
						if token_list[0] == "limport":
							# call literate_handler
							# set modulepath to literate_handler_output
							nop = 1
						else:
							modulepath = token_list[1]
						# update current_context
						# close(open_file)
						# break
					else:
						# to be implemented later
						nop = 1
			
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
			
			# elif variable_declaration == True:
				
				# variable declarations can appear anywhere except before the beginning of the module
				
				# call variable_declaration_handler
				
			
			# elif mode == "declare":
				
				# if forward_declaration
					# call declare_subroutine
				
				# if (token_list[0] == "begin") and (current module == "main"):
					# mode = "body"
				# else
					# found illegal statement in the declaration section
				
			#elif (mode == "body") or (mode == "definitions_body"):
				
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
					
			else:
				content.my_error_message('We see an unrecognized statement on line ',line_number,working_file,line)


	# wind back through all of the modules we've added in reverse order
	# stop looping when we reach the end of the first module

	else:
		if len(module_list) == 1:
			break
		else:
			del module_list[-1]


	

