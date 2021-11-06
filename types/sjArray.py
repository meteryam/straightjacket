
# arrays are always dynamic
# universal array operators:  &, []

# variable arrays are nullable by default, and if-then statements must explicitly check for nulls
# constants cannot be null

# send it to the appropriate handler

# multi-dimensional arrays are implemented as lists of arrays
# syntax:  myarray = [ [1 2 3] [4 5 6] [0 0 0] ]
# compact syntax:  myarray = [1,1:1] [2,2:1] [3,3:1]


# numeric array definitions
	
	# array operators:  append (&), addition, subtraction, transpose (^T), pseudoinverse (^-1), inner product (⋅ .), scalar multiplication (⊗) , tensor product (⊗), wedge product (∧), hodge star (★ @), cross product (x), right division (÷ /)

			# (a ∧ b) = (a ⊗ b) - (b ⊗ a)		# the commutator
			# a x b = ★(a ∧ b) = ★((a ⊗ b) - (b ⊗ a))
			# anti-commutator:  (a ∧+ b) = (a ⊗ b) + (b ⊗ a)
			
			# library idea:  geometric product
			
	# reserved signature function sig(matrix_variable):  allows programmers to use an array to define the signature of a signature array.
			



# string declarations

	# support multiple lines
	
	# strings are 8-bit integer arrays
	
	# 10-bit length chunk, elements, pointer to next chunk (if 1024 elements added)
	
	# constant strings are not dynamic
	
	# string operators:  uppercase ($), lowercase (@)
	
	# strings are integer arrays; no structural analysis
	
	
# boolean arrays
	
