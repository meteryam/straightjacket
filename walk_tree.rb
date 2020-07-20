def walk_tree(varname, treetype)

#	puts varname

	varname_split = varname.split('.')
	nodename = "_" + $currentModuleName.to_s + "_" + varname
	myvar = $currentModuleName.to_s + "_" + varname_split[0]

	if (varname_split.count == 2) && (varname_split[1] == "node") then

#		puts treetype
#		puts varname_split

		# add a new node to a tree-tracking list

#		outputFile = File.open( "output.txt","a" )
		outputFile = File.open( "cache.txt","a" )
		outputFile << "/////////////////\n"
		outputFile << "// walk the tree\n"
		outputFile << "/////////////////\n\n"
		outputFile.close

		if ($line_tokens[2].to_s == varname_split[0]) then

#			outputFile = File.open( "output.txt","a" )
			outputFile = File.open( "cache.txt","a" )

			outputFile << "_" + myvar + "_node -> " + varname_split[0] + ";\n\n"

			# nuke the entire tracking list

			outputFile << "_i = 0;\n"
			outputFile << "while (_i == 0) {\n"
			outputFile << "\t" + "if (_" + myvar + "_path == 0) {\n"
			outputFile << "\t\t" + "break;\n"
			outputFile << "\t" + "} else {\n"
			outputFile << "\t\t" + "_next_track_node = _" + myvar + "_path -> prev;\n"
			outputFile << "\t\t" + "_" + myvar + "_node = _" + myvar + "_path -> node;\n"
			outputFile << "\t\t" + "free(_" + myvar + "_path);\n"
			outputFile << "\t\t" + "_" + myvar + "_path = _next_track_node;\n"
			outputFile << "\t" + "}\n"
			outputFile << "}\n\n"
			outputFile.close
		elsif ($line_tokens[2].to_s == "max") then
#			outputFile = File.open( "output.txt","a" )
			outputFile = File.open( "cache.txt","a" )

			outputFile << "_next_track_node = (struct _track_int08_node *)malloc(sizeof(struct _track_int08_node));\n"
			outputFile << "_next_track_node -> prev = _" + $line_tokens[2].to_s.split('.')[0].to_s + "_path\n";
			outputFile << "_next_track_node -> node = _" + $line_tokens[2].to_s.split('.')[0].to_s + "_node\n";
			outputFile << "_" + myvar + "_path = _next_track_node;\n\n";

			outputFile << "_i = _" + myvar + "_node -> children;	_i = _i - 1;\n"
			outputFile << "_" + myvar + "_node = " + "_" + myvar + "_node -> ptr[_i];\n\n"

			outputFile.close
		elsif ($line_tokens[2].to_s == "prev") then
#			outputFile = File.open( "output.txt","a" )
			outputFile = File.open( "cache.txt","a" )

			outputFile << "_next_track_node = _" + myvar + "_path -> prev;\n"
			outputFile << "_" + myvar + "_node = _" + myvar + "_path -> node;\n"
			outputFile << "free(_" + myvar + "_path);\n"
			outputFile << "_" + myvar + "_path = _next_track_node;\n\n"

			outputFile.close
		elsif (treetype == "1") then

#			outputFile = File.open( "output.txt","a" )
			outputFile = File.open( "cache.txt","a" )
			outputFile << "_next_track_node = (struct _track_int08_node *)malloc(sizeof(struct _track_int08_node));\n"
			outputFile << "_next_track_node -> prev = _" + $line_tokens[2].to_s.split('.')[0].to_s + "_path\n";
			outputFile << "_next_track_node -> node = _" + $line_tokens[2].to_s.split('.')[0].to_s + "_node\n";
			outputFile << "_" + $line_tokens[2].to_s.split('.')[0].to_s + "_path = _next_track_node;\n\n";
			outputFile.close

			if ($line_tokens[2].to_s == "next") || ($line_tokens[2].to_s == "1") then
#				outputFile = File.open( "output.txt","a" )
				outputFile = File.open( "cache.txt","a" )
				outputFile << "_" + varname_split + "_node -> ptr[0];\n\n"
				outputFile.close
			else
				abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  For rank-one trees, you must use the \"next\", \"prev\" or \"max\" keywords, point to the first child node, or point to the root of the tree.")
			end

		elsif (treetype == "2") then

#			outputFile = File.open( "output.txt","a" )
			outputFile = File.open( "cache.txt","a" )
			outputFile << "_next_track_node = (struct _track_int08_node *)malloc(sizeof(struct _track_int08_node));\n"
			outputFile << "_next_track_node -> prev = _" + $line_tokens[2].to_s.split('.')[0].to_s + "_path\n";
			outputFile << "_next_track_node -> node = _" + $line_tokens[2].to_s.split('.')[0].to_s + "_node\n";
			outputFile << "_" + $line_tokens[2].to_s.split('.')[0].to_s + "_path = _next_track_node;\n\n";
			outputFile.close

			if ($line_tokens[2].to_s == "left") || ($line_tokens[2].to_s == "1") then
#				outputFile = File.open( "output.txt","a" )
				outputFile = File.open( "cache.txt","a" )
				outputFile << "_" + varname_split + "_node -> ptr[0];\n\n"
				outputFile.close
			elsif ($line_tokens[2].to_s == "right") || ($line_tokens[2].to_s == "2") then
#				outputFile = File.open( "output.txt","a" )
				outputFile = File.open( "cache.txt","a" )
				outputFile << "_" + myvar + "_node -> ptr[1];\n\n"
				outputFile.close
			else
				abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  For rank-two trees, you must use the \"left\", \"right\", \"prev\" or \"max\" keywords, point to the first or second child nodes, or point to the root of the tree.")
			end
		elsif (treetype == "") || (treetype.is_a? Integer) then		# handle other ranked trees

#			outputFile = File.open( "output.txt","a" )
			outputFile = File.open( "cache.txt","a" )
			outputFile << "_next_track_node = (struct _track_int08_node *)malloc(sizeof(struct _track_int08_node));\n"
			outputFile << "_next_track_node -> prev = _" + $line_tokens[2].to_s.split('.')[0].to_s + "_path\n";
			outputFile << "_next_track_node -> node = _" + $line_tokens[2].to_s.split('.')[0].to_s + "_node\n";
			outputFile << "_" + $line_tokens[2].to_s.split('.')[0].to_s + "_path = _next_track_node;\n\n";
			outputFile.close

			numeric = '0123456789'

			if (numeric.include?(treetype)) then
#				outputFile = File.open( "output.txt","a" )
				outputFile = File.open( "cache.txt","a" )
				outputFile << "_" + myvar + "_node -> ptr[" + $line_tokens[2].to_s + "];\n\n"
				outputFile.close
			else
				abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  For rank-n trees, nodes are indexed by number.  You may also point to the root of the tree.")
			end

		end



	else
		abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found incorrect syntax for tree walking.  Quitting compilation.")
	end

end