def bool_decl

	# later on, we'll need to wite most of this output in the main procedure

	i = $assign_list.length-1

	if $decl_list[1] == "bool" then

		while i >= 0 do

			substr = bool_literal($assign_list[i].to_s)
			$assign_list[i] = substr

			i = i-1
		end

		outputFile = File.open( "output.txt","a" )
		$assign_list.reverse_each.with_index do |token, i|

#			puts i
#			puts $assign_list.length

			$tmpnum = $tmpnum + 1

			if ($decl_list[1].to_s.include? "ternary") || ($decl_list[1].to_s.include? "fuzzy") then
				abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Only simple booleans are supported at this time.  Quitting compilation.")
			else
				if $decl_list[0].to_s == "const" then
					outputFile << "const "
				end


				# when declaring variables, mark them declared

				$identifierList.each.with_index do |identifierEntry, i|
				if (identifierEntry[0].to_s == "var") && (identifierEntry[1].to_s == $decl_list.last) then
				if (identifierEntry[3].to_s == $currentModuleName) || ($decl_list.last == identifierEntry[3].to_s + "." + $decl_list.last) then
				if $identifierList[i][10] == "no" then
					outputFile << "uint8_t "
					$identifierList[i][10] = "yes"
				end
				end
				end
				end

				if (i == $assign_list.length-1) then
					if ($currentSubroutine == "") then
						outputFile << $currentModuleName + "_"
					end
					outputFile << $decl_list[$decl_list.length-1]
				else
					outputFile << "_tmp" + ($tmpnum-1).to_s
				end

				outputFile << " = " + token + ";\n"
			end

		end

		outputFile << "\n"
		outputFile.close
	end

	$decl_list.clear

end