def procedureCall()

#	puts $line_tokens

	if ($line_tokens.last != ")") then
		abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Procedure calls must end with a close-parenthesis character.  Quitting compilation.")
	end

	procedureName = $line_tokens[0].split("(").first

	# when a procedure with a matching requirement is used, update the arrays we need to check later

	$requirements.each_with_index do |requirement, index|
		if ($line_tokens[0].split("(").first == requirement[0]) then
			$calledRequirements.push(requirement[1])
			$endList.push(["requires", requirement[1]])
			break
		end
	end

	# handle cleanup requirements list

	foundMatch = false
	$cleanupRequirements.each do |requirement|
		if (procedureName == requirement) then
			foundMatch = true
			break
		end
	end

	if (foundMatch == false) then
		$requirements.each do |requirement|
			if (procedureName == requirement[0]) then
				$cleanupRequirements.push(requirement[1])
				break
			end
		end
	end




	# when used, remove procedural requirements

	if ($endList.last[0] == "requires") && ($endList.last[1] == procedureName) then
		$endList.pop
	end

	if ($calledRequirements.last == procedureName) then
		$calledRequirements.pop
	end


	procType = []
	$identifierList.each_with_index do |identifier, updatenum|

#puts identifier

		if ($line_tokens[0].split("(").first == identifier[1]) || (($line_tokens[0].split("(").first == identifier[3] + "." + identifier[1]) && (identifier[7] == "public")) then


			$identifierList[updatenum][10] = "yes"
#puts 		identifier

			if (identifier[2].include?(",")) then
				procType = identifier[2].split(",")
			elsif (identifier[2] != "") then
				procType.push(identifier[2])
			end

			break
		end
	end

#	puts procType

	argumentlist = $line_tokens - [","] - [$line_tokens[0]]
	argumentlist.pop

	argNameList = []
	procType.each_with_index do |procTypeEntry, index|
		typeTmp = procTypeEntry.split(" ")
		argNameList.push(typeTmp.last)
		typeTmp.pop
		procType[index] = typeTmp.join(" ")
	end


#	puts argumentlist

	# check the variables for duplicates

	argumentlist.each_with_index do |argument, index|
		argumentlist.each_with_index do |listitem, index2|
			if (argument == listitem) && (index != index2) then
				$identifierList.each do |identifier|
					if (identifier[0] == "var") && ((identifier[1] == argument) || (argument == identifier[3] + "." + identifier[1])) then
						abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Duplicate variable sent to procedure.  Quitting compilation.")
					end
				end
			end
		end
	end

	# check the number of variables supplied

	if (argumentlist.count != procType.count) then
		abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Wrong number of arguments supplied to procedure.  Quitting compilation.")
	end

	# write down the procedure call

	procType.each do |typeEntry|

		type = typeEntry.split(" ")
#		puts type

		if (type[0] == "bool") then

			argumentlist.each_with_index do |argument, index|

				foundMatch = false
				$identifierList.each do |identifier|
					if (identifier[0] == "var") && ((identifier[1] == argument) || ((argument == identifier[3] + "." + identifier[1]) && (identifier[7] == "public"))) then
						foundMatch = true

						if (identifier[2] != procType[index]) then
							abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The supplied argument has the wrong type.  Quitting compilation.")
						end

						break
					end
				end

				if (foundMatch == false) then
					abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The supplied argument isn\'t a previously defined variable.  Quitting compilation.")
				end


				# don't add prefixes or create temporary variables when passing argument variables

				anotherTmp = []
				passingArg = false
				$identifierList.each do |identifier|
					if (identifier[0] == "proc") && ((identifier[1] == procedureName) || ((procedureName == identifier[3] + "." + identifier[1]) && (identifier[7] == "public"))) then
						if (identifier[2].include?(",")) then 
							anotherTmp = identifier[2].split(",")
						else
							anotherTmp.push(identifier[2])
						end

						if (anotherTmp[index].split(" ").last == argument) then
							passingArg = true
						end
						break

					end
				end

				# handle variables that aren't arguments of the originating subroutine

				if (passingArg == false) then

					if (type.count == 1) then		# create temporary variables for simple booleans
						argumentlist.each_with_index do |argument, index2|
#							outputFile = File.open( "output.txt","a" )
							outputFile = File.open( "cache.txt","a" )
							$tmpnum = $tmpnum + 1
							argumentBool = bool_literal(argument)
							outputFile << "uint8_t _tmp" + $tmpnum.to_s + " = " + argumentBool + ";\n"
							argumentlist[index2] = "&_tmp" + $tmpnum.to_s
							outputFile.close
						end
					else
						argumentlist[index] = "&" + argument + ", &_" + argument + "_node"
					end

				end
			end

			# write the actual arguments

#			outputFile = File.open( "output.txt","a" )
			outputFile = File.open( "cache.txt","a" )
			outputFile << $line_tokens[0]
			argumentlist.each_with_index do |argument, index|

				if (index == 0) then
					outputFile << argument
				else
					outputFile << "," + argument
				end

			end
			outputFile << ", &_exception);\n\n"
			outputFile.close
		else
			abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Only booleans and boolean-valued containers are supported at this time.  Quitting compilation.")
		end
	end		# procType.each

	# handle the case where a procedure has no arguments

	if (procType[0].nil?) then
#		outputFile = File.open( "output.txt","a" )
		outputFile = File.open( "cache.txt","a" )

		if (procedureName.include?(".")) then
			outputFile << procedureName + "();\n"
		else
			outputFile << $currentModuleName + "_" + procedureName + "();\n"
		end

		outputFile.close
	end

	# check for exceptions

	if (procedureName != $currentSubroutine) then

#		outputFile = File.open( "output.txt","a" )
		outputFile = File.open( "cache.txt","a" )
		outputFile << "if (*_exception != 0) { \n"
		outputFile << "\t" + "(*_exception) -> line_number = " + $currentLineNum.to_s + ";\n"
		outputFile << "\t" + "(*_exception) -> module_name = \"" + $currentModuleName + ".\\n\";\n"

		if (procedureName.include?(".")) then
			outputFile << "\t" + "goto " + procedureName + ";\n"
		else
			outputFile << "\t" + "goto " + $currentModuleName + "." + procedureName + ";\n"
		end

		outputFile << "}\n\n"
		outputFile.close
	
		foundMatch = false
		$exceptionList.each do |exception|
			if (exception == procedureName) then
				foundMatch = true
			end
		end
	
		if (foundMatch == false) then
			$exceptionList.push(procedureName)
			$nopropagate.push(procedureName)
		end
	end

end