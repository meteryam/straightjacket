def subr_decl(subrtype)

#	puts subrtype
#	puts $line_tokens[$line_tokens.count-2]
#	puts $line_tokens.count

	$calledRequirements = []

	# check return type

	returnType = ""

	if (subrtype == "func") then

		startLooking = 0
		if (subrtype == "func") then
			$line_tokens.each_with_index do |token, index|
				if (token == ")") then
					startLooking = 1
				elsif (startLooking == 1) then
					if (token == "returns") then
						startLooking = 2
					end
				elsif (startLooking == 2) then
					if (returnType == "") then
						returnType = token
					else
						returnType = returnType + " " + token
					end
				end
			end
		end

	end

	# handle procedure requirements

	if ($line_tokens[$line_tokens.count-2] == "requires") then

		if (subrtype == "func") then
			abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Only procedures may use the \"requires\" keyword.  Quitting compilation.")
		end

		foundMatch = false
		$identifierList.each do |identifier|
			if (identifier[0] == "proc") && (identifier[1] == $line_tokens[$line_tokens.count-1]) && (identifier[3] == $currentModuleName) && ($line_tokens[1].split("(").first != $line_tokens[$line_tokens.count-1]) then
				foundRequirement = false
				$requirements.each do |requirement|
					if (requirement[1] == $line_tokens[$line_tokens.count-1]) then
						foundRequirement = true
						break
					end
				end

				if (foundRequirement == false) then
					$requirements.push([$line_tokens[1].split("(").first, $line_tokens[$line_tokens.count-1]])
				end

				foundMatch = true
#				$cleanupFlag = true
				break
			end
		end

		if (foundMatch == false) then
			abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The \"requires\" keyword may only be followed by another procedure defined in the current module.  Quitting compilation.")
		end
	elsif ($line_tokens[$line_tokens.count-2] == "returns") then

		if (subrtype == "proc") then
			abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Only functions may use the \"returns\" keyword.  Quitting compilation.")
		end

	elsif (returnType == "") && (subrtype == "func") then

		abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The arguments in a function definition must be followed by the \"returns\" keyword, and then a return type.  Quitting compilation.")

	end

	if (subrtype == "proc") then
		$subrType = "proc"
	else
		$subrType = "func"
	end

	if ($line_tokens[1][$line_tokens[1].length-1] != "(") then
		abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Subroutine names must be followed immediately by open parentheses.  Quitting compilation.")
	end

	if ($currentSubroutine != "") then
		abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Subroutines cannot be declared within the bodies of other subroutines.  Quitting compilation.")
	end

	$currentSubroutine = $line_tokens[1].chomp("(")

	if ($currentSubroutine == "main") then
	if ($currentModuleName != "main") then
		abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The \"main\" procedure can only be declared within the \"main\" module.  Quitting compilation.")
	end
	end

#puts subrtype

	outputFile = File.open( "output.txt","a" )
	if (subrtype == "proc") then

		if ($currentSubroutine == "main") then
			outputFile << "uint16_t main("
		else
			outputFile << "void " + $currentModuleName + "_" + $currentSubroutine + "("
		end

	else

		if ($currentSubroutine == "main") then
			abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  \"main\" must be declared as a procedure, not a function.  Quitting compilation.")
		else
			if (returnType == "bool") then
				outputFile << "uint8_t " + $currentModuleName + "_" + $currentSubroutine + "("
			elsif (returnType == "bool tree") then
				outputFile << "struct _int08_node *" + $currentModuleName + "_" + $currentSubroutine + "("
			elsif (returnType.include?("[")) then
				if (returnType.split("[").first == "bool tree") then
					outputFile << "struct _int08_node *" + $currentModuleName + "_" + $currentSubroutine + "("
				end
			else
				abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Only booleans and boolean trees are supported at this time.  Quitting compilation.")
			end
		end

	end
	outputFile.close

	###################################
	### handle subroutine arguments ###
	###################################

	argList = []
	identifierTmp = []
	$argumentList = []

	for i in 2..$line_tokens.length

		if ($line_tokens[i] == ",") || ($line_tokens[i] == ")") then

			if ($currentSubroutine == "main") && (argList[0].nil? == false) then
				abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The main procedure cannot have arguments.  Quitting compilation.")
			end




			# evaluate argList

			if (identifierTmp[0].to_s != "[]") then
				$identifierList.push(identifierTmp)
			end



			identifierTmp = []

			if (argList[0] == "bool") then
				if (argList.count == 2) then	# found simple boolean

					# add each argument to $identifierList so that we can detect duplicates
		
					identifierTmp = ["var", argList[1], argList[0], $currentModuleName, $currentSubroutine, "", "", "", "", "", "yes"]
		
					$identifierList.each do |identifier|
		
						if (identifierTmp.join.to_s == identifier.join.to_s) then 
							abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found duplicate identifier.  Quitting compilation.")
						end
		
					end

					# write out the argument list, followed by the exception handling argument

					outputFile = File.open( "output.txt","a" )
					outputFile << "uint8_t *" + argList[1]
					if ($currentSubroutine != "main") then
						outputFile << ",struct _exception_node **_exception"
					end
					outputFile << $line_tokens[i]
					outputFile.close

				elsif (argList[1] == "tree") || (argList[1].split("[").first == "tree") then

#					puts $identifierList

					# add each argument to $identifierList so that we can detect duplicates
		

					identifierTmp = ["var", argList[2], argList[0] + " " + argList[1], $currentModuleName, $currentSubroutine, "", "", "", "", "", "yes"]

					$identifierList.each do |identifier|
		
						if (identifierTmp.join.to_s == identifier.join.to_s) then 
							abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found duplicate identifier.  Quitting compilation.")
						end
		
					end

#					puts identifierTmp

					$identifierList.push(identifierTmp)


					# make sure the tree keyword is used properly

					testNum = ""

					if (argList[1].include?("[")) || (argList[1].include?("]")) then

						if (argList[1].include?("[")) ^ (argList[1].include?("]")) then
							abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The square brackets associated with the tree type must be paired.  Quitting compilation.")
						end

						testNum = argList[1].split("[").last.split("]").first
	
#						puts testNum

						if (testNum.scan(/\D/).empty? == false) then
							abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The square brackets associated with the tree type must contain an integer value.  Quitting compilation.")
						elsif (Integer(testNum)-1 > 18446744073709551615) then
							abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Only 18,446,744,073,709,551,615 children per node are permitted.  Quitting compilation.")
						end

					end

					# write out the argument list, followed by the exception handling argument
					# pass both the tree and its cursor

					outputFile = File.open( "output.txt","a" )
					outputFile << "struct _int08_node *" + argList[2] + "," + "struct _int08_node *" + argList[2] + "_node"
					if ($currentSubroutine != "main") then
						outputFile << ",struct _exception_node **_exception"
					end
					outputFile << $line_tokens[i]
					outputFile.close

				else
					abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Type #{argList[0]} not supported.  Quitting compilation.")
				end
			elsif (argList[0].nil?) then
#puts "here i am!"
				outputFile = File.open( "output.txt","a" )
				if ($currentSubroutine != "main") then
					outputFile << "struct _exception_node **_exception"
				end
				outputFile << ")"
				outputFile.close
			else
				abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Type not supported.  Quitting compilation.")
			end


			$argumentList.push(argList.join(" "))
			argList.clear
		else

			# build the argList array

			if ($line_tokens[i].nil? == false) then
				argList.push($line_tokens[i])
			end
		end

		if ($line_tokens[i].length == 1) && ($line_tokens[i] == ")") then
			break
		end
		
	end

	if (i+2 == $line_tokens.count) then		# handle forward declarations
		if ($line_tokens.last != "fwd") then
			abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The argument of a subroutine must be followed either by the keyword \"fwd\" or by nothing.  Quitting compilation.")
		else
			# handle forward declarations
			outputFile = File.open( "output.txt","a" )
			outputFile << ";\n\n"
			outputFile.close
		end
	else

		# declare the exception flag

		if ($mode != "private") then
			abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Forward declarations are permitted within public sections, but subroutine definitions aren\'t.  Quitting compilation.")
		end

		outputFile = File.open( "output.txt","a" )
		outputFile << " {\n"
		outputFile << "uint8_t _exceptionFlag = 0;\n"				# initialize the exception flag
		outputFile << "uint8_t _exceptionAbortFlag = 0;\n"			# initialize the exception abort condition
#		outputFile << "struct _exception_node *_tmpexception;\n"	# initialize the exception node variable
		outputFile.close

		outputFile = File.open( "cache.txt","a" )
		outputFile << "begin:\n\n"
		outputFile.close


		$endList.push(["end", $currentSubroutine]);

#		puts($currentSubroutine);

	end


	afterArg = ""
	if (returnType != "") then
		afterArg = returnType
	elsif ($line_tokens[$line_tokens.count-2] == "requires") then
		afterArg = $line_tokens[$line_tokens.count-1]
	end

	# add the subroutine to $identifierLest

	if ($line_tokens.last == "fwd") then
		$identifierList.push([subrtype, $currentSubroutine, $argumentList.join(";"), $currentModuleName, "fwd", afterArg, "", $mode, "", "", "no"])
	else
		$identifierList.push([subrtype, $currentSubroutine, $argumentList.join(";"), $currentModuleName, "", afterArg, "", $mode, "", "", "no"])
	end

#	puts $identifierList

end