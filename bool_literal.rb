def bool_literal(inputstr)

#	puts inputstr

	testStr = ""
	testChar = ""
	finishedStr = ""
	lparen = 0
	rparen = 0
	quotes = 0

	# format input strings to create whitespace-separated tokens

	inputstr.split("").each_with_index do |char, index|
#		puts lparen.to_s + " " + rparen.to_s

		if (char != " ") && (char != "\t") then
			testChar = char
		else
			testChar = ""
		end

		if (index == 0) then
			if (char == "(") then
				finishedStr = finishedStr + testChar + " "
			else
				finishedStr = finishedStr + testChar
			end
		else
			if (inputstr[index] == "(") then
				lparen = lparen + 1
			elsif (inputstr[index] == ")") then
				rparen = rparen + 1
			end

			if (inputstr[index-1] == "(") && (char != " ") && (char != "\t") then
				finishedStr = finishedStr + testChar
			elsif (char == ")") && (inputstr[index-1] != " ") && (inputstr[index-1] != "\t") then
				if (lparen != rparen) then
					finishedStr = finishedStr + " " + testChar
				else
					lparen = 0
					rparen = 0
					finishedStr = finishedStr + testChar
				end
			else
				if (lparen != rparen) then
					finishedStr = finishedStr + testChar
				else
					lparen = 0
					rparen = 0
					finishedStr = finishedStr + char
				end
			end
		end

	end

	inputstr = finishedStr

	# split up the finished string into a string array

	checkItems = finishedStr.split(" ") - ["("] - [")"] - ["or"] - ["not"] - ["xor"] - ["and"] - ["true"] - ["false"]

	# check each item in the list

	loop do
		checkItems.each_with_index do |item, index|
#			puts item

			# when functions are found, check them
			# then add their arguments to the list of items to check
	
			if (item.include?("(")) then
				# handle function calls
	
				checkFunction = item.split("(").first
				checkArgs = item[(checkFunction.length+1)..-2].split(",")
	
				foundMatch = false
				$identifierList.each do |identifier|
					if (identifier[0] == "func") && ((identifier[1] == checkFunction) || ((checkFunction == identifier[3] + "." + identifier[1]) && (identifier[7] == "public")))
						foundMatch = true
						break
					end
				end
	
				if (foundMatch == false) then
					abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found undeclared function.  Quitting compilation.")
				end
	
				checkItems = checkItems - [checkItems[index]]
	
				checkArgs = checkArgs - ["true"] - ["false"]
				continueLoop = true
				checkItems.push(checkArgs)
	
	#			puts checkArgs
	
			else
				# handle variables
	
				foundMatch = false
				$identifierList.each do |identifier|
					if ((identifier[0] == "var") || (identifier[0] == "const")) && ((identifier[1] == item) || ((item == identifier[3] + "." + identifier[1]) && (identifier[7] == "public")))
						foundMatch = true
	#					checkItems = checkItems - checkItems[index]
						break
					end
				end
	
				if (foundMatch == false) then
					abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found undeclared variable.  Quitting compilation.")
				end
	
				checkItems = checkItems - [checkItems[index]]
	
			end
	
		end

		# if we've deleted every item in checkItems, stop looping
		# otherwise, just keep going

		if (checkItems.first.nil?) then
#			puts checkItems.first
			break
		end
	end

#	puts checkItems

	# translate the straightjacket input to something c can understand

	inputstr = inputstr.gsub(/\bfalse\b/, '0')
	inputstr = inputstr.gsub(/\btrue\b/, '1')
	inputstr = inputstr.gsub(/\bor\b/, '||')
	inputstr = inputstr.gsub(/\band\b/, '&&')
	inputstr = inputstr.gsub(/\bnot\b/, '!')

	if inputstr.include? " xor " then
		xorlist = inputstr.split(" xor ")

		substr = "(" + xorlist[0] + " || " + xorlist[1] + ") && !(" + xorlist[0] + " && " + xorlist[1] + ")"

		j = 2
		while j <= xorlist.length-1 do

			substr = "(" + substr + " || " + xorlist[j] + ") && !(" + substr + " && " + xorlist[j] + ")"

			j = j + 1
		end

		inputstr = substr
	end

	# process function calls

#	puts inputstr.split(" ")

#	$funExprExceptions = []
	validFunc = false
	testInputStr = inputstr.split(" ")

	testInputStr.each_with_index do |input, index|

		$identifierList.each do |identifier|
			if (identifier[0] == "func") && ((input.start_with?(identifier[1] + "(")) || ((input.start_with?(identifier[3] + "." + identifier[1] + "(")) && (identifier[7] == "public"))) then
				validFunc = funccall(input, "bool")		# throw errors if something's wrong with the function call
				if (validFunc == true) then
					$exceptionList.push(identifier[3] + "." + identifier[1])

					exceptionFile = File.open( "cache.txt","a" )
					$tempnum = $tempnum + 1
					exceptionFile << "_tmp" + $tempnum.to_s + " = " + input + ";\n\n"	# write the function output to a temporary value
					testInputStr[index] = "_tmp" + $tempnum.to_s		# replace the function call with the temporary value

					exceptionFile << "if (*_exception != 0) { \n"
					exceptionFile << "\t" + "(*_exception) -> line_number = " + $currentLineNum.to_s + ";\n"
					exceptionFile << "\t" + "(*_exception) -> module_name = \"" + $currentModuleName + ".\\n\";\n"
					exceptionFile << "\t" + "goto " + identifier[3] + "." + identifier[1] + ";\n"
					exceptionFile << "}\n\n"
					exceptionFile.close

#					$funExprExceptions.push(identifier[3] + "." + identifier[1])
				end
				break
			end
		end

	end

	inputstr = testInputStr.join(" ")	# incorporate function call string replacements into the return value

	return inputstr
end