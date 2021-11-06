

# if-then combs

# generic loop statements

# abort statements

# foreach loops



# no export commands within control structures

# defSubroutine(1,snippet,exportFlag,forwardFlag)

def defSubroutine(subroutine_type_int, snippet, exportFlag, forwardFlag):
	if (subroutine_type_int == 1):
		print('Found function definiton.')
		
	elif (subroutine_type_int == 2):
		print('Found procedure definiton.')
		
	elif (subroutine_type_int == 3):
		print('Found main program.')
	
	print(snippet)
	
	# automatic type coercion for subroutines that accept lists as arguments
	# generic list type:  numeric signed, numeric unsigned
	# the existence of generic numeric lists requires automatic type coercion
	
	# variable declarations
	
		# booleans
		
		# arrays
		
		# structs
		
		# lists
		
		# custom types
		
		
		# rich booleans
		
		# characters
		
		# strings
		
		# integers
		
		# matrices
		
		# floats
		
		# complex
	
	# variable assignments


	# if combs
		
		# null checks must come first
	
		# pattern matching
	
	# repeat loops
	
	# foreach loops
	
	# if (len(lineChunks) > 2) and (lineChunks[1] == '='):
		
		# nop = 1
		
		###############################
		# handle variable assignments #
		###############################
		
		# check types for agreement
		
			# handle function calls
			# call sjControl.callSubroutine(2,funStr)
			
		# call sjControl.pipe
		
		# various types...
	
	# elif (lineChunks[0] == 'abort'):
		
		# nop = 1

		# call sjControl.abort
		
	# else:
		
		# nop = 1
		
		# check for procedure calls...
		
		# check for type conversions
		
			# call sjConversions
			
				# int2float
				# float2int
				# etc...

	return 'testString'
	