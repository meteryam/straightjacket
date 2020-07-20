
=begin

At this point, we need to define a function to tokenize each line.  Having this function will make the translation process much easier later on.  Here are the possible tokens we might see in straightjacket:

simple_t3rm

A simple term is a string of letters, numbers and underscores.  They are generally enclosed by whitespace.

`string with spaces`

Although there isn't a native string type in Straightjacket, the compiler should recognize quoted strings as arrays of integers and translate them accordingly.  Straightjacket's quote is the backquote, chosen to avoid clashing with the single and double quotes, both of which arise in both English and in everyday computer interfaces (like shells).  Single characters must also be quoted.

((parenthesized with spaces) ())

Trees are represented as s-expressions - simple terms surrounted by parentheses.  Each left-handed parenthesis must be matched with a right-handed parenthesis, and trees can span multiple lines for the programmer's convenience.

someArray[variable `string` 2.0 ]

Arrays are written as simple terms followed by left square brackets, followed by zero or more other terms, and ending with right square brackets.

subroutine( return:int spam:int eggs:int )
subroutine( `string` )

Subroutine declarations, definitions and calls are all written as simple terms followed by left parentheses, followed by zero or more other terms, and ending with right parentheses.

+ - * ^ / & > <
÷ ≥  ≤  ≠

If certain operators appear within or adjascent to simple terms, the compiler should treat them as if they were separated from them by whitespace.  Thus, x-1 becomes x - 1 without thowing a warning or complaint.

// /% %/

Comment operators should be separated from other text by whitespace.  Multi-line comments begin with /% and end with %/, and can be nested.


=end

def tokenize(line, flag)

	if flag == 'literate' then
		phase = 'literate'
	else
		phase = 'beginning'
	end

	line_array = Array[]

	whitespace = ' ' + "\t"
	simple = '_:abcdefghijklmnopqrstuvwxyz0123456789'
	numeric = '0123456789'
	operators = '+-*^/&><=÷≥≤≠.'

	stringarray = 0

#	puts numeric

	i = 0
	currentToken = ''

#	puts phase

	while i <= line.length do

		if phase == 'literate' then
			if numeric.include?(line[i]) then
				currentToken << line[i]
			elsif line[i] == "\t" then
				line_array.push(currentToken)
				phase = 'beginning'
			elsif (line[i] == "\r") || (line[i] == "\n") then
				break
			else
				line_array.push(currentToken)
				currentToken = '$' + line[i]		# the $ character isn't used in straightjacket, so it's a good way to mark invalid code
				phase = 'gibberish'
			end

		elsif phase == 'beginning' then
			if (line[i] == "\t") || (line[i] == ' ') then		# leading tabs are significant; straightjacket uses the off-side rule
#				line_array.push(line[i])
			elsif simple.include?(line[i]) then
				currentToken = line[i].downcase
				phase = 'simple'
#				puts currentToken
			elsif (line[i] == '@') || (line[i] == '#') then
					# the @ symbol is a leading sigil used to designate exported symbols as read-only
					# the # symbol is a leading sigil used to call special OS-specific subroutines provided by the compiler
				currentToken = line[i].downcase
				phase = 'simple'
			elsif (line[i] == '/') && (line[i+1] == '/') then	# single-line comments begin with //
				if currentToken != "" then 
					line_array.push(currentToken)
				end
				phase = 'comment'
			elsif (line[i] == '/') && (line[i+1] == '%') then	# multi-line comments begin with /%
				currentToken << line[i] + line[i+1]
				line_array.push(currentToken)
				phase = 'whitespace'
				currentToken = ''
				$multiLcomment = $multiLcomment + 1
				i = i + 1
			elsif (line[i] == '%') && (line[i+1] == '/') then	# multi-line comments end with %/
				currentToken << line[i] + line[i+1]
				line_array.push(currentToken)
				phase = 'whitespace'
				currentToken = ''
				$multiLcomment = $multiLcomment - 1
				i = i + 1
			elsif (line[i] == "\r") || (line[i] == "\n") then
				break
			elsif (line[i] == "(") then
				currentToken = line[i]
				phase = 'paren'
			else
				line_array.push(currentToken)
				currentToken = '$' + line[i]
				phase = 'gibberish'
			end
		elsif phase == 'comment' then
			# do nothing
		elsif phase == 'end_comment' then
			currentToken << line[i]
			line_array.push(currentToken)
			currentToken = ''
			phase = 'whitespace'
		elsif phase == 'simple' then

			if simple.include?(line[i]) then
				currentToken << line[i].downcase
#				puts currentToken
			elsif (line[i] == '>') && (line[i-1] == '-') then
				currentToken << line[i].downcase
			elsif line[i] == '.' then	# struct fields are addressed using periods
				currentToken << line[i]
			elsif line[i] == '[' then	# array tokens are followed immediately by left brackets
				currentToken = currentToken + line[i]
				phase = 'array'
#				puts "here i am!"
			elsif (line[i] == "\t") || (line[i] == ' ') then
				line_array.push(currentToken)
				phase = 'whitespace'
#				puts "here i am!"
			elsif operators.include?(line[i]) then
#				puts 'here i am!'
				line_array.push(currentToken)
				line_array.push(line[i])
				phase = 'whitespace'
			elsif line[i] == '|' then	# tree labels are separated from their nodes by vertical bars
				line_array.push(currentToken)
				line_array.push(line[i])
				phase = 'whitespace'
			elsif line[i] == '(' then	# function and list tokens are followed immediately by left parentheses
				currentToken << line[i]
				line_array.push(currentToken)
				phase = 'whitespace'
			elsif line[i] == ')' then	# function arguments and list tokens are closed by right parentheses
				line_array.push(currentToken)
				currentToken = line[i]
				if (i == line.length - 2) then
					line_array.push(currentToken)
				end
				phase = 'whitespace'
			elsif line[i] == ',' then	# definitions for subroutine arguments and struct fields are separated by commas
				line_array.push(currentToken)
				line_array.push(line[i])
				phase = 'whitespace'
#				puts 'here i am!'
			elsif (line[i] == '/') && (line[i+1] == '/') then	# single-line comments begin with //
				if currentToken != "" then 
					line_array.push(currentToken)
				end
				phase = 'comment'
			elsif (line[i] == "\r") || (line[i] == "\n") then
				line_array.push(currentToken)
				break
			else
				line_array.push(currentToken)
				currentToken = '$' + line[i]
				phase = 'gibberish'
			end
		elsif phase == 'whitespace' then

			currentToken = ''

			if (line[i].to_s == '/') && (line[i+1].to_s == '/') then	# found single-line comment
				phase = 'comment'
			elsif (operators.include?(line[i])) || (line[i] == ',') then
				currentToken = line[i]
				phase = 'simple'
			elsif simple.include?(line[i]) then
				currentToken = line[i].downcase
				phase = 'simple'
			elsif (line[i] == '/') &&  (line[i+1] == '%') then		# found beginning of multi-line comment
				currentToken << line[i] + line[i+1]
				line_array.push(currentToken)
				currentToken = ''
				$multiLcomment = $multiLcomment + 1
				i = i + 1
			elsif (line[i] == '%') &&  (line[i+1] == '/') then		# found end of multi-line comment
				currentToken << line[i] + line[i+1]
				line_array.push(currentToken)
				currentToken = ''
				$multiLcomment = $multiLcomment - 1
				i = i + 1
			elsif line[i] == '`' then	# string literals are enclosed within reverse-quotes
				currentToken = line[i]
				phase = 'string'
			elsif (line[i] == '|') || (line[i] == ')') || (line[i] == ']') then
				line_array.push(line[i])
			elsif (line[i] == "(") then
				currentToken = line[i]
				phase = 'paren'
			elsif (line[i] == ")") then
				line_array.push(line[i])
				currentToken = ""
			elsif (line[i] == "\r") || (line[i] == "\n") then
				break
			elsif (line[i] == " ") || (line[i] == "\t") then
				# ignore whitespace
			else
				line_array.push(currentToken)
				currentToken = '$' + line[i]
				phase = 'gibberish'
			end

		elsif phase == 'array' then

			currentToken = currentToken + line[i]

			if (line[i] == ']') && (stringarray == 0) then
				line_array.push(currentToken)
				phase = 'whitespace'
			end

			if (line[i] == '`') && (line[i-1] != '\\') then
				if stringarray == 0 then
					stringarray = 1	
				else
					stringarray = 0
				end
			end

		elsif phase == 'paren' then

			currentToken = currentToken + line[i]

			if currentToken.scan('(').length == currentToken.scan(')').length then
				line_array.push(currentToken)
				phase = 'whitespace'
			end

		elsif phase == 'string' then

			currentToken << line[i]

			if (line[i] == '`') && (line[i-1] != '\\') then		# backslashes are used to escape backquotes
				line_array.push(currentToken)
				currentToken = ''
				phase = 'whitespace'
			end

		elsif phase == 'gibberish' then
			currentToken << line[i]
#			puts "found gibberish!"
			abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Character is \"#{currentToken}\", phase is \"#{phase}\".  Unable to split input line into tokens.  Quitting compilation.")
		end

		i = i + 1

#		puts ' ' + phase
	end

#	puts line_array

	return line_array
end