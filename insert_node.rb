def insert_node(nodevalue)

#	puts "nodevalue: " + nodevalue.to_s

	if (nodevalue[2].split(" ").last.split("[").last.split("]").first != "") then
		rank = nodevalue[2].split(" ").last.split("[").last.split("]").first
	else
		rank = "n"
	end

	if $line_tokens[0].to_s.include?('.') then
		firsttoken_split = $line_tokens[0].to_s.split(".")
	else
		firsttoken_split = [$line_tokens[0].to_s]
	end

	# check to see whether we're already checking for null trees
	nullcheck = false
	$flow_control_list.last.each do |field|
		if (field.to_s == firsttoken_split[0].to_s) then
			nullcheck = true
			break
		end
	end

	nodechoice = ""

	nodename = "_" + $currentModuleName.to_s + "_" + firsttoken_split[0].to_s + "_node"
	varname = $currentModuleName.to_s + "_" + firsttoken_split[0].to_s

#	puts nodevalue[1]
#	puts nodevalue[2].split(" ").last
	puts "firsttoken_split: " + firsttoken_split.to_s

	if (firsttoken_split.count == 1) then

		if (nullcheck == true) || ((nodevalue[1].to_s == firsttoken_split[0]) && (nodevalue[2].split(" ").last == "tree[1]")) then
			# handle tree appending case (lists and null trees)

			nodechoice = "0"

		else
			abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Wrong syntax used to add a node.")
		end
	elsif (firsttoken_split.count == 2) then

		if (nodevalue[1].to_s == firsttoken_split[0]) && (nodevalue[2].split(" ").last == "tree[1]") then
			# handle node appending case (lists only)

			nodechoice = "0"
		else
			abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Wrong syntax used to add a node.")
		end
	elsif (firsttoken_split.count == 3) then

		numeric = '0123456789'

		if (nodevalue[1] == firsttoken_split[0]) && (nodevalue[2].split(" ").last == "tree[]") && (numeric.include?(firsttoken_split.last.to_s)) && (firsttoken_split.last.to_s != "0") then
			# rank-n trees need to specify the node number

			nodechoice = (Integer(firsttoken_split.last)-1).to_s

			if (Integer(firsttoken_split.last)-1 > 18446744073709551615) then
				abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Specified rank is too large.")
			end

		elsif (nodevalue[1].to_s == firsttoken_split[0]) && (nodevalue[2].split(" ").last == "tree[2]") && (firsttoken_split[2].to_s == "left") then
			# binary trees need to specify whether to append to the left or right nodes

			nodechoice = "0"

		elsif (nodevalue[1].to_s == firsttoken_split[0]) && (nodevalue[2].split(" ").last == "tree[2]") && (firsttoken_split[2].to_s == "right") then
			# binary trees need to specify whether to append to the left or right nodes

			nodechoice = "1"

		else
			abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Wrong syntax used to add a node to a tree of this type.")
		end

	else
		abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Wrong syntax used to add a node.")
	end


	# datafield and add_nodetype set by node type

	selectType = nodevalue[2].to_s.split(" ")
	selectType.pop
#	puts selectType.last

	if rank == "n" then
		rank = 1
	end

	if ($line_tokens[2][0] != "(") && ($line_tokens[2][-1] != ")") then
		abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Tree literals must begin and end with parentheses.")
	end



	if (selectType.last.to_s == "bool") then

#		outputFile = File.open( "output.txt","a" )
		outputFile = File.open( "cache.txt","a" )

		nodeptr = 0
		nodetrack = 0
		i = 0
		currentStr = ""
		foundParen = 0
		foundVar = false
		lParenTrack = 0
		rParenTrack = 0

#		puts nodevalue[2].split("[").last.split("]").first

		while (i < $line_tokens[2].length) do
	
#			puts rank.to_s + " " + lParenTrack.to_s + " " + rParenTrack.to_s

			if (rank == "1") && ((lParenTrack > 1) || (rParenTrack > 1)) then
				abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Branched nodes cannot be assigned to rank-1 trees.  Quitting compilation.")
			end

			if ($line_tokens[2][i] == "(") then
				nodetrack = 0
				currentStr = ""
				foundParen = foundParen + 1
				lParenTrack = lParenTrack + 1
			elsif ($line_tokens[2][i] == ")") then
				nodeptr = 0
				nodetrack = nodetrack - 1
				rParenTrack = rParenTrack + 1

				# walk up the tree a nodetrack number of times

				while (nodetrack > 0) do

					outputFile << nodename + " = _" + varname + " -> node;\n"
					outputFile << "_next_track_node = _" + varname + "_path -> prev;\n"
					outputFile << "free(_mytree_path);\n"
					outputFile << "_" + varname + "_path = _next_track_node;\n\n"

					nodetrack = nodetrack - 1

				end

				foundParen = foundParen - 1

				# take care of variables

				if (currentStr != "") && (currentStr != "true") && (currentStr != "false") then
					$identifierList.each do |listEntry|
						if (listEntry[1] == currentStr) && (listEntry[2] == "bool") then
							foundVar = true
							break
						end
					end

					if (foundVar == false) then
						abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found unrecognized identifier.  Quitting compilation.")
					end
				end

			elsif (($line_tokens[2][i] != " ") && ($line_tokens[2][i] != "\t")) then
				currentStr = currentStr + $line_tokens[2][i]
			end

			if (i > 0) && (i != $line_tokens[2].length - 1) && (foundParen == 0) then
				abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found empty set of parentheses.  Quitting compilation.")
			end
		
			if (currentStr == "true") || (currentStr == "false") || (foundVar == true) then

#				puts "hello"

				nodetrack = nodetrack + 1

				# add node with value bool_literal(currentStr)
		

				datafield = bool_literal($line_tokens[2].to_s)
				datafield2 = bool_literal(currentStr)
			
				outputFile << "////////////\n"
				outputFile << "// add node\n"
				outputFile << "////////////\n\n"
		
				outputFile << "_newnode = (struct _int08_node *)calloc(sizeof(struct _int08_node));\n"
				outputFile << "_newnode -> data = " + datafield2 + ";\n"
				outputFile << "if (" + nodename + " == 0) {\n"
				outputFile << "\t" + varname + " = _newnode;\n"
				outputFile << "\t" + nodename + " = " + varname + ";\n"
				outputFile << "} else if (" + nodename + " -> ptr == 0) {\n"
				outputFile << "\t" + nodename + " -> ptr = (struct _int08_node **)calloc(n * sizeof(struct _int08_node*));\n"
				outputFile << "\t" + nodename + " -> ptr[" + nodeptr.to_s + "] = _newnode;\n"
				outputFile << "} else {\n"
				outputFile << "\t" + nodename + " -> ptr[" + nodeptr.to_s + "] = _newnode;\n"
				outputFile << "}\n\n"

				outputFile << "_next_track_node = (struct _track_int08_node *)malloc(sizeof(struct _track_int08_node));\n"
				outputFile << "_next_track_node -> prev = _" + varname + "_path;\n"
				outputFile << "_next_track_node -> node = " + nodename + ";\n"
				outputFile << "_" + varname + "_path = _next_track_node;\n"
				outputFile << nodename + " = " + nodename + " -> ptr[" + nodeptr.to_s + "];\n\n"

				currentStr = ""
				testEmpty = ""
				nodeptr = 1

				writenode = false
				walkup = false

			end


	
#			puts $line_tokens[2][i]
			i = i + 1

		end

		outputFile.close

	end


end