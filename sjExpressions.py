
# def booleanAssignment(snippet):
	
	# assignments
	
	# myBool = TRUE
	
	# simple booleans:  represented as unsigned integer bytes
	# vallues:  can be TRUE, FALSE
	# non-nullable
	
	
	# myBool = NULL(0.5)
	
	# rich booleans:  represented as two-element unsigned integer byte arrays
		# the first element represents truth vs falsity
		# the second element represents a condition that is neither true nor false (eg indeterminable)
		# the sum of both elements should never exceed 1
	# values:  TRUE, FALSE, NULL, TRUE(0.5), NULL(0.5)
	# nullable:  programmers must explicitly check for NULL values
	

# treat functions of untyped lists as generic functions
# automatic type coercion of non-list arguments
# stricter typer coercion rules for type lists (eg structs cannot be typed)