def funccall(processStr, outsideReturnType)

	processArray = [""]
	lparens = -1
	rparens = 0
	token = ""
	foundFunc = false
	processArg = false
	
	processStr.split("").each_with_index do |char, index|
	
		if (token != "") || (char != " ") then
			token = token + char
		end
	
		if (processArg == false) && (char == "(") && (token != "") then
			processArray.push(token)
			token = ""
			processArg = true
			lparens = lparens + 1
		elsif (processArg == false) && (char == ")") then
			token = token[0..-2]
			processArray.push(token)
			processArray.push(")")
			token = ""
			processArg = false
		elsif (processArg == false) && (char == ",") then
			token = token[0..-2]
			processArray.push(token)
			token = ""
		elsif (processArg == true) && (char == ")") then
			lparens = lparens + 1
			processArray.push(token[0..-2])
			processArray.push(")")
			token = ""
			processArg = false
		elsif (index == processStr.length-1) then
			processArray.push(token)
		end
	
	end

	processArray = processArray - [","] - [""] - [nil]
	if (processArray.last.to_s == "[]") then
		processArray.pop
	end

#	puts processArray
#	puts $identifierList
#	puts
	
	foundFunc = false
	processArgs = false
	i = 0
	numArgs = 0
	currentFunc = ""
	argList = []
	foundIdentifier = false
	args_with_types = [[]]
	reference_types = []
	foundMatch = false
	isFunc = []
	
	
	# check return type of the outer function call
	
	$identifierList.each do |identifier|

		if (identifier[0] == "func") && ((processArray[0][0..-2] == identifier[1]) || ((processArray[0][0..-2] == identifier[3] + "." + identifier[3]) && (identifier[7] == "public"))) then

			if (outsideReturnType != identifier[5]) && (outsideReturnType != identifier[5].split("[").first) then
				abort("Error in module \"#{$currentModuleName.strip}\".  Found call to function with improper return type.  Quitting compilation.")
			end

			break
		end

	end


	
	loop do

		foundargs = []

		if (processArray[i].nil? == false) then
			lparens = processArray[i].count("(")
			rparens = processArray[i].count(")")

			if (foundFunc == false) then
	
				if (lparens != rparens) && (processArray[i][-1, 1] == "(") then
					foundFunc = true
					processArgs = true
					currentFunc = processArray[i]
				elsif (lparens == rparens) then
					processArray = processArray - [processArray[i]]
				end
			else
		
				if (lparens != rparens) && (processArray[i][-1, 1] == "(") && (processArray[i] != "(") then
					processArgs = false
					if (processArray[i] != "(") then
						numArgs = numArgs + 1
						argList.push(processArray[i])
					end
				elsif (lparens != rparens) && (processArray[i][-1, 1] == ")") && (processArray[i] != ")") then
					processArgs = true
				elsif (processArgs == true) && (processArray[i] != "(") && (processArray[i] != ")") then
					numArgs = numArgs + 1
					argList.push(processArray[i])
				elsif (processArgs == false) && (processArray[i] == ")") then
					processArgs = true
				end
			end

#		else
#			break
		end
	
		processArray = processArray - [nil]
	
		if (i == processArray.length - 1) then

			isFunc = []	
#			puts "currentFunc: " + currentFunc

			argList2 = []
			argListTmp = []

			if (outsideReturnType == "bool") then

				argList.each do |arg|
					argListTmp = arg.split(",")
					argListTmp.each do |arg|
						argList2.push(arg)
					end
				end

			end

			argList = argList2 - [nil] - [""]
#			puts argList
	
			referenceFunc = ""
	
			# check arguments against $identifierList
	
			foundIdentifier = false
			$identifierList.each_with_index do |identifier, index|

				# check variables
	
				argList.each_with_index do |arg, deletenum|
	
					if ((identifier[0] == "var") || (identifier[0] == "const")) && ((arg == identifier[1]) || ((arg == identifier[3] + "." + identifier[1]) && (identifier[7] == "public"))) then

						# check argument type against variable's type
		
						$identifierList.each_with_index do |referenceID, index2|
							if (referenceID[0] == "func") && ((currentFunc == referenceID[1] + "(") || ((currentFunc == referenceID[3] + "." + referenceID[1] + "(") && (referenceID[7] == "public"))) then
								if (referenceID[2].split(";").count == argList.count) then
									if (referenceID[2].split(";")[index2] == identifier[2]) then
										foundargs.push(arg)
										foundMatch = true
										break
									else
										abort("Error in module \"#{$currentModuleName.strip}\".  Variable with the wrong type supplied to function " + currentFunc + ".  Quitting compilation.")
									end

								else
									abort("Error in module \"#{$currentModuleName.strip}\".  Wrong number of arguments supplied to function.  Quitting compilation.")
								end
							end
						end

						break
				
					end
				end
	


				argList.each_with_index do |arg, index3|

#puts arg.to_s
#puts identifier.to_s
	
					if (identifier.to_s != "[]") then
					if (identifier[0] == "func") || ((currentFunc == identifier[1] + "(") || ((currentFunc == identifier[3] + "." + identifier[1] + "(") && (identifier[7] == "public"))) then
	
#						puts "arg: " + arg

						foundFunc = false
						testStr = ""
						passFuncArgs = []
						currentArgs = []
	
						arg.split("").each do |char|
	
							returnType = ""
	
							testStr = testStr + char
	
							if (char == "(") & (foundFunc == false) then
								foundMatch = true
	
#								puts "testStr: " + testStr
#								puts "identifier[1]: " + identifier[1]

								foundFunc = true

								$identifierList.each do |entry|

									# collect the return type of the function we found
									# collect the arguments of the function we found

									if (entry[0] == "func") && ((testStr == entry[1] + "(") || ((testStr == entry[3] + "." + entry[1] + "(") && (entry[7] == "public"))) then
										passFuncArgs = entry[2].split(";")
										returnType = entry[5]
										foundMatch = true

									# collect the arguments of the current function

									elsif (entry[0] == "func") && ((currentFunc == entry[1] + "(") || ((currentFunc == entry[3] + "." + entry[1] + "(") && (currentFunc[7] == "public"))) then
										currentArgs = entry[2].split(";")
									end

									if (returnType != "") && (currentArgs[0].to_s != "[]") then
										break
									end
								end

								# todo:  throw error if number of arguments is wrong

								# check the argument type of the current function

								if (returnType != currentArgs[index3]) && (returnType != "") then
									abort("Error in module \"#{$currentModuleName.strip}\".  Found function call " + arg + " with the wrong return type.  Quitting compilation.")
								elsif (returnType != currentArgs[index3]) && (returnType == "") then
									abort("Error in module \"#{$currentModuleName.strip}\".  Found undeclared function call " + arg + ".  Quitting compilation.")
								else
									foundargs.push(arg)
								end

								testStr = ""

							elsif (foundFunc == true) && ((char == ",") || (char == ")")) then
	
								testStr = testStr[0..-2].strip!
	
								# check if argument is a variable
	
								foundMatch = false
								$identifierList.each_with_index do |varname, index4|
									if ((varname[0] == "var") || (varname[0] == "const")) && ((testStr == varname[1]) || ((testStr == varname[3] + "." + varname[1]) && (varname[7] == "public"))) then
	
										if (varname[2] != currentArgs[index3]) then
											abort("Error in module \"#{$currentModuleName.strip}\".  Found variable with the wrong return type.  Quitting compilation.")
										end
		
										foundMatch = true
										break
									end
								end
	
								# if not found, check for literal value
	
								if (foundMatch == false) then
	
									if (outsideReturnType == "bool") then
										if (testStr != "true") && (testStr != "false") then
											abort("Error in module \"#{$currentModuleName.strip}\".  Found incorrect literal value for boolean type.  Quitting compilation.")
										end
									else
										abort("Error in module \"#{$currentModuleName.strip}\".  Found unsupported data type or unsupported literal.  Quitting compilation.")
									end
	
								else
									foundargs.push(arg)
									break
	
								end
	
							end
	
						end
	
						if (foundMatch == true) then
							foundIdentifier = true
							break
						end
	
					end
					end
	
				end
	
			end
	
	
			# if no identifier found, check the remaining arguments for literal values, based on the type expected for currentFunc
	
			isFunc = isFunc - ["", nil]
	
			if (isFunc.to_s != "[]") then
				argList = argList - foundargs - isFunc
	
				isFunc.each do |func| 
					abort("Error in module \"#{$currentModuleName.strip}\".  Found call to undeclared function.  Quitting compilation.")
				end
		
			else
				argList = argList - foundargs
			end
	
			argList.each do |arg|
	
				arg.sub!("(", " ")
				arg.sub!(")", " ")
				arg.sub!("and", " ")
				arg.sub!("xor", " ")
				arg.sub!("or", " ")
				arg.sub!("true", " ")
				arg.sub!("false", " ")
				arg.strip!
	
				if (arg != "") then
					abort("Error in module \"#{$currentModuleName.strip}\".  Quitting compilation; found incorrect value " + arg)
				end
	
			end
	
			# cleanup code
	
			processArray.each_with_index do |entry, index|
				if (entry.count("(") == entry.count(")")) then
					processArray = processArray - [processArray[index]]
				else
					break
				end
			end
	
			processArray.reverse_each do |entry|
				if (entry.count("(") == entry.count(")")) || (entry == "(") then
					processArray.pop
				else
					break
				end
			end
	
			processArray = processArray - [processArray.first]
			if (processArray.last == ")") then
				processArray = processArray - [processArray.last]
			end
	
			if (numArgs == 0) then
				break
			else
				numArgs = 0
			end
	
			argList = []
			currentFunc = ""
			foundFunc = false
			i = 0
	
			puts
		end
	
		i = i + 1

		if (processArray.first == "") then
			break
		end
	
	
	end
	
	# todo:  translate quoted strings

	return true
end