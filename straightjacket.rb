
require 'fileutils'
require 'io/console'
require 'date'


# declare various global variables


$exceptionList = []
$nopropagate = []
#$funExprExceptions = []
$currentIndent = 0
$multiLcomment = 0
$currentLineNum = 0
$currentModuleName = ""
$moduleList = [["_path", "_alias"]]
$decl_list = Array[]
$assign_list = Array[]
$tmpnum = 0
$line_tokens = Array[]
$heapObjects = [[]]
$mode = ""
$endList = [[]]
$currentSubroutine = ""
$subrType = ""
$funReturn = ""
$foundFunReturn = false
$tempnum = 0
$safetyCheckList = []

$identifierList = [["_identifiertype", "_name", "_type", "_module", "_subroutine_or_fwd", "_withintype", "_const", "_exported", "_readonly", "_numeric", "_called_or_value"]]
$withinType = ""
$const = ""
$exportedVal = ""
$readonly = ""
$numeric = ""
$argumentList = []
#$currentFileName = ''
$requirements = [[]]			# list of associations between procedues and their requirements
$calledRequirements = []		# requirements that haven't been fulfilled from within the body of the subroutine
$cleanupRequirements = []		# requirements that haven't been fulfilled from within the exception cleanup section
$cleanupFlag = false

=begin

The first thing the compiler needs to do is to make sure that its temporary files area is set up properly.  If it isn't, then the compiler needs to correct that.

=end

if Dir.exists?('C:\temp') == false then Dir.mkdir('C:\temp') end
if Dir.exists?('C:\temp\sj') == false then Dir.mkdir('C:\temp\sj') end
if Dir.exists?('C:\temp\sj\output') == false then Dir.mkdir('C:\temp\sj\output') end
if Dir.exists?('C:\temp\sj\literate') == false then Dir.mkdir('C:\temp\sj\literate') end


# checking arguments and setting literate flag

literateflag = false
filename = ''


if ARGV.length == 0 then

	puts 'no arguments found'

elsif ARGV.length == 1 then

	filecheck = File.exists?(ARGV[0])

	if filecheck == false then
		abort('If one argument is supplied, then it must be a file.  Quitting compilation.')
	else
		filename = ARGV[0]
		literateflag = false
	end

elsif ARGV.length == 2 then

	if ARGV[0] == '-l' then
		literateflag = true
	else
		abort('If two arguments are supplied, then the first argument must be a valid option.  Quitting compilation.')
	end

	filecheck = File.exists?(ARGV[1])

	if filecheck == false then
		abort('The second argument must be a file.  Quitting compilation.')
	else
		filename = ARGV[1]
	end

elsif ARGV.length > 2 then

	abort('The straightjacket compiler takes no more than two arguments.  Quitting compilation.')

end

filecheck == false

# set the present working directory (pwd) to the directory that holds the input file

mydirname = File.dirname(filename)
Dir.chdir(mydirname)



# define literate procedure in case we need it

load 'literate.rb'




# if the literateflag is true, apply the literate procedure to the input file.  also set the main module's status in a special hash table.

fileStatus = Hash.new()

if literateflag == true then 
	$currentFileName = literate(filename)
	fileStatus["main"] = "literate"
else
	$currentFileName = filename
	fileStatus["main"] = "illiterate"
end



# define tokenization procedure in case we need it

load 'tokenize.rb'




# define paren_split procedure in case we need it

load 'paren_split.rb'




# define procedure to check boolean assignments

def checkboolassign(assignment)

	# need to re-write this procedure

	assignment = assignment.gsub(/\bfalse\b/, '')
	assignment = assignment.gsub(/\btrue\b/, '')
	assignment = assignment.gsub(/\bor\b/, '')
	assignment = assignment.gsub(/\band\b/, '')
	assignment = assignment.gsub(/\bxor\b/, '')
	assignment = assignment.gsub('(', '')
	assignment = assignment.gsub(')', '')

	assignment = assignment.strip

#	puts assignment
#	puts $identifierList[linenum]

	if assignment != "" then
		abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found mis-assigned boolean value.  Quitting compilation.")
	end

end


=begin

Before we can process input modules, we'll have to define handlers for each type of properly-formatted line in the Straightjacket language...

=end


# boolean literal handler

load 'bool_literal.rb'




# boolean assignment handler

load 'bool_decl.rb'



# tree assignment handler

# for values assigned at initialization time, pass off to the expression handler afterwards
# tree expression handler assignment, appending trees and scalars, line continuations

def bool_tree_decl

	# declare the tree variable

	modulePrefix = ""
	if ($currentSubroutine.to_s == "") then
		modulePrefix = $currentSubroutine.to_s + "_"
	end

	varname = $line_tokens.last

	outputFile = File.open( "output.txt","a" )

	if (modulePrefix.strip!.nil? == false) then
		outputFile << "struct _int08_node *" + modulePrefix + varname + ";" + "\n"
		outputFile << "struct _int08_node *" + "_" + modulePrefix + varname + "_" + "node" + ";" + "\n"
		outputFile << "struct _track_int08_node *" + "_" + modulePrefix + varname + "_" + "path" + ";" + "\n\n"
		outputFile << modulePrefix + varname + " = 0;\n"
		outputFile << "_" + modulePrefix + varname + "_" + "node = " + modulePrefix + varname + ";\n\n"
	else
		outputFile << "struct _int08_node *" + varname + ";" + "\n"
		outputFile << "struct _int08_node *" + varname + "_" + "node" + ";" + "\n"
		outputFile << "struct _track_int08_node *" + varname + "_" + "path" + ";" + "\n\n"
		outputFile << varname + " = 0;\n"
		outputFile << varname + "_" + "node = " + varname + ";\n\n"
	end

	outputFile.close

	$heapObjects.push(["bool tree", varname])

end


# define procedure to append nodes to trees

$flow_control_list = Array[["if", "mytree"]]

load 'insert_node.rb'



# define procedure to walk down the tree, one node at a time

load 'walk_tree.rb'




# handle subroutine declarations (forward or otherwise)

load 'subr_decl.rb'



# handle procedure calls

load 'procedureCall.rb'



# check function calls

load 'funccall.rb'



####################
### main program ###
####################

=begin

Now that we can both tokenize a line and handle those tokens appropriately, we'll process each module line by line.  The main module contains the program's primary code, while other modules imported by it contain additional variables, constants and subroutines.  These modules may in turn import other modules, although this isn't required.  Each module has its own namespace, and every public term called from a module must be preceded by the name of the module from whence it came.  This arrangement prevents name collisions between modules.

Most modules have the following structure:

	module moduleName

	[import moduleName]		used for standard modules
	[import file]			used for custom modules
	[limport file]			used for literate modules

	public

	[declarations]

	private

	[declarations]

	[subroutine definitions]

Each item listed in brackets is optional.  In addition to all of this, the main module must have the module name "main" and it cannot contain a public section.

While running through each module, we'll compile a list of all of the modules it imports.  Once this has been done, we'll translate the code, starting from the last module added.  To avoid dependency issues, we'll output four c files:

	- program_name.c:  contains code from the main module (not including subroutines defined there)
	- imports.c:  contains any native c resources our compiler needs
	- declarations.c:  contains all module-global declarations and assignments
	- subroutines.c:  contains all subroutine definitions (except for the main() procedure)

To ensure predictable program behavior, these files should be imported into the program_name.c file first, and in this order.

=end


numLparens  = 0
numRparens  = 0
numLbrack   = 0
numRbrack   = 0
multiLineComment = 0
numReqTabs	= 0

breakloop = false

outputFile = File.open( "output.txt","w" )
outputFile << ""
outputFile.close

outputFile = File.open( "cache.txt", "w" )
outputFile << ""
outputFile.close

processMe = 1
assignStr = ""

skipImportCheck = false
usingModules = false

$fileList = Hash.new()
$fileList[$currentFileName] = 'main'

while breakloop == false do

	$insert_tree_flag = false

	$fileList.reverse_each do |key, value|

		$currentFileName = key
		$currentModuleName = value
		currentFileStatus = fileStatus[$currentModuleName]


		if (currentFileStatus == 'literate') || (currentFileStatus == 'illiterate') then

			$mode = 'beginning'
			$currentLineNum = 0

			myFile=File.open($currentFileName,"r")
			while(inputline=myFile.gets)

				if myFile.eof? then
					inputline = inputline + "\n"		# needed if the last line in the file contains code
				end

				$line_tokens = tokenize(inputline, currentFileStatus)

				puts inputline
#				puts $line_tokens
#				puts $line_tokens[0].to_s.strip
#				puts $line_tokens
#				puts $multiLcomment

				if ($multiLcomment < 0) then
					abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found too many tokens indicating an end to multi-line comments.  Quitting compilation.")
				end

				fieldToStart = 0
				$line_tokens.each_with_index do |entry, count|
					if (entry.strip! == "%/") then
						fieldToStart = count + 1
					end
				end

				if currentFileStatus == 'literate' then
					$currentLineNum = $line_tokens[0].to_i + 1
					$line_tokens.shift
				else
					$currentLineNum = $currentLineNum + 1
				end

				if ($multiLcomment == 0) && (fieldToStart < $line_tokens.length) then
	
					if $line_tokens[0].strip == "" then
						# do nothing with empty lines
					else
	
						if ($mode == 'public') || ($mode == 'private') then
		
							if ($line_tokens[0] == 'private') then
								$mode = 'private'
							end

#							puts "$mode: " + $mode
		
							foundAssignment = 0
							processMe = 0
		
							# handle declarations
		
							$decl_list.clear
		
							if ($line_tokens[0].to_s == 'var') || ($line_tokens[0].to_s == 'const') then
		
								if ($cleanupFlag == true) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The exception cleanup section can only contain procedure calls.  Quitting compilation.")
								end

								processMe = 1
		
								assignStr = ""
		
		#						puts "here i am!"
		
								$assign_list.clear
		
								$decl_list[0] = $line_tokens[0]
		
								# fill $decl_list and (if necessary) $assign_list
		
		
								foundAssignment = 0
		
								$line_tokens.each.with_index do |token, i|
									if token == "=" then
										foundAssignment = 1
									else
										if foundAssignment == 0 then
											$decl_list[i] = $line_tokens[i]
										else
											assignStr = assignStr + $line_tokens[i] + " "
										end
									end
								end
		
		#						puts $decl_list
		
								typeStr = ""
								i = 1
								while i < $decl_list.length-1 do
		#							puts "decl_list: " + $decl_list[i].to_s
									typeStr = typeStr + $decl_list[i].to_s + " "
									i = i + 1
								end
								typeStr = typeStr.chomp
		
								if $decl_list.last[0] == "$" then
									$readonly = "readonly"
								end
		
								# look for name clashes
		
								$identifierList.each do |testEntry|
		
									if (testEntry[0].to_s == $line_tokens[0].to_s) && (testEntry[1].to_s == $decl_list.last) && (testEntry[3].to_s == $currentModuleName) && (testEntry[4].to_s == $currentSubroutine) && (testEntry[5].to_s == $withinType) then
		
										abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found duplicate declaration.  Quitting compilation.")
		
									end
		
								end
		
		
								$identifierList.push(["var", $decl_list.last, typeStr.strip!, $currentModuleName, $currentSubroutine, $withinType, $decl_list[0], $mode, $readonly, $numeric, "no"])
		
							elsif ($line_tokens[0].to_s == 'proc') then

								if ($cleanupFlag == true) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The exception cleanup section can only contain procedure calls.  Quitting compilation.")
								end

								subr_decl("proc")

							elsif ($line_tokens[0].to_s == 'func') then

								if ($cleanupFlag == true) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The exception cleanup section can only contain procedure calls.  Quitting compilation.")
								end

								subr_decl("func")

								$foundFunReturn = false

							elsif ($line_tokens[0].to_s == 'raise') then

								if ($cleanupFlag == true) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The exception cleanup section can only contain procedure calls.  Quitting compilation.")
								end

								if ($line_tokens.count == 2) then

#									outputFile = File.open( "output.txt","a" )
									outputFile = File.open( "cache.txt","a" )

									if ($currentException != "") then
										outputFile << "free(*_exception_node);\n"
									end

									outputFile << "*_exception_node = (struct _exception_node *)malloc(sizeof(struct _exception_node));\n"
									outputFile << "(*_exception_node) -> line_number = " + $currentLineNum.to_s + ";\n"
									outputFile << "(*_exception_node) -> module_name = \"" + $currentModuleName + ".\\n\";\n"
									outputFile << "(*_exception_node) -> exception_name = \"" + $line_tokens[1] + "\\n\";\n"
									outputFile << "(*_exception_node) -> exitcode = 1;\n"

									if ($currentException != "") then
										outputFile << "_exceptionAbortFlag = 1;\n"
									end

									outputFile << "goto " + $line_tokens[1] + ";\n\n"
									outputFile.close

									$exceptionList.push($line_tokens[1])

								else
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Raise statements must be followed by single arguments.  Quitting compilation.")
								end

							elsif ($line_tokens[0] == 'except') then

								if ($cleanupFlag == true) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Exception handlers must be placed before the \"exception cleanup\" section.  Quitting compilation.")
								end

								if ($calledRequirements.last.nil? == false) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  All \"required\" procedures must be called from within the \"exception cleanup\" section.  Quitting compilation.")
								end

								if ($line_tokens[1] == "when") && ($line_tokens.count == 3) then

									$currentException = $line_tokens[2]
#									outputFile = File.open( "output.txt","a" )
									outputFile = File.open( "cache.txt","a" )

									# check $exceptionList for a match with $line_tokens[2]

									foundMatch = false
									$exceptionList.each_with_index do |exception, index|
										if (exception == $line_tokens[2]) then
											$exceptionList = $exceptionList - [$line_tokens[2]]
											foundMatch = true

											# check $nopropagate to prevent propagation of subroutine exceptions
#											$nopropagate.each do |nopropagate|
#												if (nopropagate == exception) then
													outputFile << "_exceptionFlag = 1;\n"
#												end
#											end

											# free the exception node

											outputFile << "free((*_exception_node) -> module_name);\n"
											outputFile << "free((*_exception_node) -> exception_name);\n"
											outputFile << "free(*_exception_node);\n"
											outputFile << "*_exception_node = 0;\n\n"

											$exceptionList.delete(index)

											outputFile << "goto " + "cleanup;\n\n"
											outputFile << exception + ":\n"

											break
										end
									end

									outputFile.close

									if (foundMatch == false) then
										abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found exception handler for an exception that cannot arise in this subroutine.  Quitting compilation.")
									end

								else
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The keyword \"except\" must be followed by the keyword \"when\" and a valid exception name.  Quitting compilation.")
								end

							elsif ($line_tokens[0] == 'exception') then

								if ($line_tokens[1] != "cleanup") then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The \"exception\" keyword must be followed by keyword \"cleanup\".  Quitting compilation.")
								end

								$cleanupFlag = true

#								outputFile = File.open( "output.txt","a" )
								outputFile = File.open( "cache.txt","a" )

								# create exception sections

								outputFile << "goto " + "cleanup;\n\n"

								$exceptionList.each do |exception|
									outputFile << exception + ":\n"
									outputFile << "fprintf(stderr, (*_exception_node) -> exception_name);\n"
									outputFile << "fprintf(stderr, \"Error found on line \");\n"
									outputFile << "fprintf(stderr, \"%d\", (*_exception_node) -> line_number);\n"
									outputFile << "fprintf(stderr, \"in module \");\n"
									outputFile << "fprintf(stderr, \"%d\", (*_exception_node) -> module_name);\n"

									if ($currentSubroutine == "main") then
										outputFile << "_exceptionAbortFlag = (*_exception_node) -> exitcode;\n"
									end

									outputFile << "goto " + "cleanup;\n\n"
								end

								$exceptionList = []
								$nopropagate = []

								outputFile << "cleanup:\n"

									outputFile.close

							elsif ($line_tokens[0] == 'end') then

								# handle end statements

								processMe = 0
								foundEntry = false

								if ($line_tokens.count == 1) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The \"end\" statement must be followed by the subroutine name or control flow structure type that it encloses.  Quitting compilation.")
								end

								if ($currentSubroutine == $line_tokens[1]) then
									$subrType = ""
									$currentException = ""
								end

								if ($endList.count == 0)  then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found too many end statements.  Quitting compilation.")

								elsif ($endList.last[0] == "end") && ($endList.last[1] == $line_tokens[1]) then

									if ($calledRequirements.last.nil? == false) || ($cleanupRequirements.last.nil? == false) then
										abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  All procedures marked \"required\" must be called from within both the body of the subroutine and the \"exception cleanup\" section.  Quitting compilation.")
									end

#									outputFile = File.open( "output.txt","a" )
									outputFile = File.open( "cache.txt","a" )

									# create exception sections

									if ($cleanupFlag == false) then
										outputFile << "goto " + "cleanup;\n\n"
	
										$exceptionList.each do |exception|
											outputFile << exception + ":\n"
											outputFile << "fprintf(stderr, (*_exception_node) -> exception_name);\n"
											outputFile << "fprintf(stderr, \"Error found on line \");\n"
											outputFile << "fprintf(stderr, \"%d\", (*_exception_node) -> line_number);\n"
											outputFile << "fprintf(stderr, \"in module \");\n"
											outputFile << "fprintf(stderr, \"%d\", (*_exception_node) -> module_name);\n"
	
											if ($currentSubroutine == "main") then
												outputFile << "_exceptionAbortFlag = (*_exception_node) -> exitcode;\n"
											end
	
											outputFile << "goto " + "cleanup;\n\n"
										end
	
										$exceptionList = []
										$nopropagate = []

										outputFile << "cleanup:\n"
									end

									# free heap objects at the end of a subroutine

									if ($currentSubroutine != "main") then
										$heapObjects.each do |heapobject|
											if (heapobject[0] == "bool tree") && (heapobject[1] != $funReturn) then		# don't free heap objects you're returning
												outputFile << "\t" + "deltree_int08(&" + heapobject[1] + ", &_" + heapobject[1] + "_node, &_" + heapobject[1] + "_path);\n"
											end
										end
									end

									$heapObjects = []

									outputFile << "\t" + "if (_exceptionFlag != 0) { exit(_exceptionAbortFlag); }\n"

									if ($currentSubroutine == "main") then
										outputFile << "return 0;\n"
									elsif ($subrType == "proc") then
										outputFile << "return;\n"
									else
										if ($foundFunReturn == true) then

											$identifierList.each do |identifier|
												if (identifier[0] == "func") && ($currentSubroutine == identifier[1]) && (identifier[3] == $currentModuleName) then
													if (identifier[5] == "bool") then
														funReturn_bool = bool_literal($funReturn)
														outputFile << "return " + funReturn_bool + ";\n"
													elsif (identifier[5] == "bool tree") || (identifier[5].split("[").first == "bool tree") then
														foundMatch = false
														$identifierList.each do |identifier2|
															if (identifier2[0] == "var") && ($currentSubroutine == identifier2[4]) && (identifier2[3] == $currentModuleName) then
																outputFile << "return *" + $funReturn + ";\n"
																foundMatch = true
															end
														end

														if (foundMatch == false) then
															abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found attempt to return an undeclared variable.  Quitting compilation.")
														end

													end
													break
												end
											end

										else
											abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  No \"return\" statement found in function body.  Quitting compilation.")
										end
									end

									outputFile << "}\n\n"
									outputFile.close


									# merge output files

									inputFile = File.open( "cache.txt","r" )
									outputFile = File.open( "output.txt","a" )
									inputFile.each do |inputline|

										outputFile << inputline

									end
									outputFile.close
									inputFile.close

									outputFile = File.open( "cache.txt","w" )
									outputFile << ""
									outputFile.close

									foundEntry = true
									$currentSubroutine = ""
									$endList.pop

									$cleanupFlag = false

								else
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Expected procedure call to \"#{$endList.last[1]}\".  Quitting compilation.")
								end

							elsif ($line_tokens[0].to_s == 'return') then

								if ($cleanupFlag == true) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The exception cleanup section can only contain procedure calls.  Quitting compilation.")
								end

								if ($subrType == "proc") then
									if ($line_tokens.count == 1) then
#										outputFile = File.open( "output.txt","a" )
										outputFile = File.open( "cache.txt","a" )
										outputFile << "goto " + "cleanup;\n\n"
										outputFile.close
									else
										abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Return statements for procedures cannot have arguments.  Quitting compilation.")
									end
								elsif ($subrType == "func") then

									if ($line_tokens.count == 2) then
										$funReturn = $line_tokens[1]
										$foundFunReturn = true

#										outputFile = File.open( "output.txt","a" )
										outputFile = File.open( "cache.txt","a" )
										outputFile << "goto " + "cleanup;\n\n"
										outputFile.close
									else
										abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  A function\'s return statement must have exactly one argument.  Quitting compilation.")
									end

								else
										abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Return statements must be located within subroutines.  Quitting compilation.")
								end

							elsif ($line_tokens[0].to_s == 'abort') then

								if ($cleanupFlag == true) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The exception cleanup section can only contain procedure calls.  Quitting compilation.")
								end

								processMe = 0

								if ($currentSubroutine.nil?) || ($currentSubroutine == "") then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  \"abort\" statements must be located within subroutines.  Quitting compilation.")
								end

								errnum = 0
								if ($line_tokens.length == 1) then
									errnum = 0
								elsif ($line_tokens.length == 2) then
									begin
										errnum = Integer($line_tokens[1]).abs
									rescue
										abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Argument supplied to \"abort\" statement isn't an integer.  Quitting compilation.")
									end
								end

								if (errnum > 32767) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Argument supplied to \"abort\" statement is outside of the allowable range.  Quitting compilation.")
								end

#								outputFile = File.open( "output.txt","a" )
								outputFile = File.open( "cache.txt","a" )
								outputFile << "exit(" + errnum.to_s + ");\n\n"
								outputFile.close

							elsif ($line_tokens[0] == 'deletree') then		# found a tree deletion statement

								$identifierList.each do |listEntry|
								
									subtoken = $line_tokens[0].to_s.split('.')
								
									if (listEntry[0] == "var") && (listEntry[1] == $line_tokens[0]) then
										if ((listEntry[2] == 'bool tree') || (listEntry[2].to_s.split('[').first == 'bool tree')) && ($line_tokens[2] == "null") then	# found boolean tree assignment to null
											outputFile = File.open( "cache.txt","a" )
											outputFile << "deltree_int08(&" + $line_tokens[0] + ", &_" + $line_tokens[0] + "_node, &_" + $line_tokens[0] + "_path);\n\n"
											outputFile.close
											foundMatch = true
											break
										end
									end
								end

							elsif ($line_tokens[0] == 'delete') then	# found a node deletion
		
								if ($subrType == "func") then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Delete statements cannot be used in functions.  Quitting compilation.")
								end

								if ($cleanupFlag == true) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The exception cleanup section can only contain procedure calls.  Quitting compilation.")
								end

								if ($currentSubroutine.strip!.nil?) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  \"delete\" statements must be located within subroutines.  Quitting compilation.")
								end

								nodecheck = $line_tokens[1].split('.')
		
								if (nodecheck.last != "node") then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  When deleting a node from a variable, you must append \".node\" to the end of the variable name.  Quitting compilation.")
								end
		
								myvar = $currentModuleName.to_s + "_" + nodecheck[0]
		
								$identifierList.each do |listEntry|
									checkEntry = listEntry[1]
		
									rank = listEntry[2].split('[').last.split(']').first
		
									if (checkEntry == nodecheck[0]) then
		
										if (listEntry[2].to_s.include? 'tree') then
		
											# free the current node, and then move up to the previous node
		
#											outputFile = File.open( "output.txt","a" )
											outputFile = File.open( "cache.txt","a" )
		
											outputFile << "/////////////////\n"
											outputFile << "// delete a node\n"
											outputFile << "/////////////////\n\n"
		
											# set old node pointer to null
											outputFile << "for (_i = 0; _i < _tmpchildren; _i++) {\n"
											outputFile << "\t" + "if (_" + myvar + "_path != 0) {\n"
											outputFile << "\t\t" + "if (_" + myvar + "_node == _" + myvar + "_path -> node -> ptr[_i]) {\n"
											outputFile << "\t\t\t" + "_" + myvar + "_path -> node -> ptr[_i] = 0;\n"
											outputFile << "\t\t" + "}\n"
											outputFile << "\t" + "}\n"
											outputFile << "}\n\n"
		
											# delete the current node
											outputFile << "if (_" + myvar + "_node != 0) {\n"
											outputFile << "\t" + "if (_" + myvar + "_node -> ptr != 0) {\n"
											outputFile << "\t\t" + "free(_" + myvar + "_node -> ptr);\n"
											outputFile << "\t" + "}\n"
											outputFile << "\t" + "free(_" + myvar + "_node -> next);\n"
											outputFile << "}\n"
											outputFile << "free(_" + myvar + "_node);\n\n"
		
											# move to previous node
											outputFile << "_" + myvar + "_node = _" + myvar + "_path -> node;\n\n"
		
											# remove most recent node from path
											outputFile << "_next_track_node = _" + myvar + "_path -> prev;\n"
											outputFile << "free(_" + myvar + "_path);\n"
											outputFile << "_" + myvar + "_path = _next_track_node;\n\n"
		
											# resize the next pointer array
											outputFile << "if (_" + myvar + "_path != 0) {\n"
											outputFile << "\t" + "_tmplength = _" + myvar + "_path -> node -> children;\n"
											outputFile << "\t" + "_i = _tmpchildren;\n"
											outputFile << "\t" + "for (; _i > 0; _i = _i - 1) {\n"
											outputFile << "\t\t" + "if (_" + myvar + "_path -> node -> ptr[_i-1] != 0) {\n"
											outputFile << "\t\t\t" + "break;"
											outputFile << "\t\t" + "}\n"
											outputFile << "\t" + "}\n"
		
											# if all next pointers point to nothing, free the next pointer array
											outputFile << "\t" + "if (_i = 0) {\n"
											outputFile << "\t\t" + "free(_" + myvar + "_node -> ptr);\n"
											outputFile << "\t\t" + "_" + myvar + "_node -> ptr = 0;\n"
		
											# trim null pointers from next pointer array in rank-n arrays
											if (rank == "") then
												outputFile << "\t" + "} else {\n"
												outputFile << "\t\t" + "if (_i < _tmplength) {\n"
												outputFile << "\t\t\t" + "_tmplength = _i;\n"
												outputFile << "\t\t\t" + "_newarray = (struct _int08_node **)calloc(_tmplength * sizeof(struct _int08_node*));\n"
												outputFile << "\t\t\t" + "for ( _i = 0; _i <= _tmpchildren; ) {\n"
												outputFile << "\t\t\t\t" + "_newarray[_i] = _" + myvar + "_node -> ptr[_i];\n"
												outputFile << "\t\t\t\t" + "_i++;\n"
												outputFile << "\t\t\t" + "}\n"
												outputFile << "\t\t\t" + "free(_" + myvar + "_node -> ptr);\n"
												outputFile << "\t\t\t" + "_" + myvar + "_node -> ptr = _newarray;\n"
												outputFile << "\t\t" + "}\n"
											end
		
											outputFile << "\t" + "}\n"
											outputFile << "}\n\n"
		
											outputFile.close
		
										end
									end
								end
		
							elsif $line_tokens[1].to_s == '=' then

								# prohibit function updates to global values

								if ($subrType == "func") then
									$identifierList.each do |identifier|
										if (identifier[0] != "func") && ($line_tokens[0] == identifier[1]) && (identifier[4] == "") then
											abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Functions cannot assign values to global identifiers.  Quitting compilation.")
										end
									end
								end

								if ($cleanupFlag == true) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The exception cleanup section can only contain procedure calls.  Quitting compilation.")
								end

								if ($currentSubroutine.nil?) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Assignments must be located within subroutines.  Quitting compilation.")
								end

								processMe = 1
		
								assignStr = ""
								foundAssignment = 0
								$line_tokens.each.with_index do |token, i|
									if token == "=" then
										foundAssignment = 1

										if ($mode == "public") && ($line_tokens[0] != "const") then
											abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found variable assignment within a public section.  Quitting compilation.")
										end
									else
										if foundAssignment == 1 then
											assignStr = assignStr + $line_tokens[i] + " "
										end
									end
								end
		
								$identifierList.each.with_index do |identifierEntry, i|
		
#									puts identifierEntry
		
									if (identifierEntry.nil? == false) then
									if (identifierEntry[0] == "var") && (identifierEntry[1] == $line_tokens[0]) then
									if ($currentModuleName == identifierEntry[3].to_s) || (($line_tokens[0].to_s == identifierEntry[3].to_s + "." + identifierEntry[1].to_s) && (identifierEntry[7].to_s == "public")) then
		
										if (identifierEntry[6].to_s == "const") then
											abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found assignment to a constant.  Quitting compilation.")
										end
		
										if ($line_tokens[0].to_s == identifierEntry[3].to_s + "." + identifierEntry[1].to_s) && (identifierEntry[7].to_s == "public") && (identifierEntry[8].to_s == "readonly") then
											abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found assignment to a variable or constant exported as read-only.  Quitting compilation.")
										end
		
		#								puts "found variable " + $line_tokens[0].to_s
		
										if identifierEntry[2].to_s.include? "bool" then
		#									checkboolassign(assignStr)	# need to rewrite this procedure
											processMe = 1
											foundAssignment = 1
										end
									elsif ($line_tokens[0].to_s == identifierEntry[3].to_s + "." + identifierEntry[1].to_s) && (identifierEntry[7].to_s == "private") && (identifierEntry[3].to_s != $currentModuleName) then
										abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found assignment to a private variable or constant in another module.  Quitting compilation.")
									end
									end
									end
		
								end
							elsif $line_tokens[1].to_s == '&'

								# prohibit function updates to global values

								if ($subrType == "func") then
									$identifierList.each do |identifier|
										if (identifier[0] != "func") && ($line_tokens[0] == identifier[1]) && (identifier[4] == "") then
											abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Functions cannot assign values to global identifiers.  Quitting compilation.")
										end
									end
								end

								if ($cleanupFlag == true) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The exception cleanup section can only contain procedure calls.  Quitting compilation.")
								end

								if ($currentSubroutine == "") then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Tree appends must be located within subroutines.  Quitting compilation.")
								end

								processMe = 1
								foundAssignment = 0
							elsif $line_tokens[1].to_s == '->'

								if ($cleanupFlag == true) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The exception cleanup section can only contain procedure calls.  Quitting compilation.")
								end

								if ($currentSubroutine.strip!.nil?) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Tree walking must be done within subroutines.  Quitting compilation.")
								end

								processMe = 1
								foundAssignment = 0
							else

								# check for procedure calls

								if ($line_tokens[0].include?("(")) then

									# make sure the cleanup section only contains required procedure calls
									# necessary?

									foundMatch = false
									if ($cleanupFlag == true) then

										$cleanupRequirements.each_with_index do |requirement, index|


											if (requirement == $line_tokens[0].split("(").first.to_s) then
												foundMatch = true
												$cleanupRequirements = $cleanupRequirements - [$cleanupRequirements[index]]
												break
											end
										end

										if (foundMatch == false) then
											abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Procedures called from within the exception cleanup section must be limited to those procedures that are marked \"required\" by procedures called from within the current context.  Quitting compilation.")
										end
									end

									# call the procedure

									foundMatch = false
									$identifierList.each do |identifier|
										if (identifier[0] == "proc") then
											if ($line_tokens[0].split("(").first == identifier[1]) || (($line_tokens[0].split("(").first == identifier[3] + "." + identifier[1]) && (identifier[7] == "public")) then
												foundMatch = true

												if ($subrType == "func") then
													abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Procedures cannot be called from within functions.  Quitting compilation.")
												end

												procedureCall
												break
											end
										end
									end

									if (foundMatch == false) then
										abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found call to undeclared procedure.  Quitting compilation.")
									end
								end

							end
		
							$assign_list = paren_split(assignStr)
							inline_assignment = []

							###################################################################
							# call the highest-level handler by walking $decl_list in reverse #
							###################################################################
		
							if processMe == 1 then
		
#								puts $decl_list.count
		
								if $decl_list.count > 0 then	# found declaration
		
#									puts $decl_list
		
									$decl_list.reverse_each do |token|

#										puts $line_tokens

										if (token == "tree") || (token.split('[').first == "tree") then
		
											if ($assign_list.count > 0) && ($assign_list.to_s.strip != "[\"\"]") then
#												puts assignStr
												inline_assignment.push($line_tokens[$line_tokens.count - 3])
												inline_assignment.push($line_tokens[$line_tokens.count - 2])
												inline_assignment.push($line_tokens[$line_tokens.count - 1])
												$line_tokens.pop
												$line_tokens.pop
#												insert_node(assignStr)

#												puts $line_tokens
#												abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found tree assignment on the same line as a declaration.  Quitting compilation.")
											end
		
		#									puts "found tree"
											bool_tree_decl
											break
										elsif token == "bool" then
											if foundAssignment == 0 then
												$assign_list[0] = "false"
											end
											bool_decl
											break
										end
									end

									# found inline tree assignment

									if ($assign_list.count > 0) && ($assign_list.to_s.strip != "[\"\"]") then

										$line_tokens.clear
										if (inline_assignment[0].nil? == false)
											inline_assignment[0] = inline_assignment[0] + ".node"
										end
										if (inline_assignment[1].nil? == false)
											inline_assignment[1] = "&"
										end
										$line_tokens = inline_assignment
										$decl_list.clear
										$insert_tree_flag = true

#										puts inline_assignment
#										puts assignStr
#										$line_tokens.clear
#										$line_tokens.push(
#										insert_node(assignStr)

#										puts $line_tokens
#										abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found tree assignment on the same line as a declaration.  Quitting compilation.")
									end

								end

								if ($decl_list.count <= 0) && ($line_tokens[1].to_s == "=")	# found assignment

									puts $line_tokens
			
									if ($line_tokens[0].to_s.include? '.') then		# found tree or struct
										subtoken = $line_tokens[0].to_s.split('.')

										if (subtoken[1].to_s == "node") && (subtoken.count == 2) then
		
											$identifierList.each do |listEntry|
												checkEntry = listEntry[1].to_s.split('[')
			
												if checkEntry[0].to_s == subtoken[0].to_s then
			
													if (listEntry[2].to_s.include? 'tree') then
														if (listEntry[2].to_s.include? 'bool') then
#															outputFile = File.open( "output.txt","a" )
															outputFile = File.open( "main_cache.txt","a" )

															testStr = ""
															testStr = $line_tokens[2]
															testStr = testStr.gsub(/\bfalse\b/, '')
															testStr = testStr.gsub(/\btrue\b/, '')
															testStr.gsub!(/\s+/, '')
															testStr = testStr.gsub(/[()]/, "")

#															puts "testStr||"
#															puts "testStr|" + testStr + "|"

															foundVar = false
															if (testStr == "") then
																foundVar = true

															else
																$identifierList.each do |listEntry|
																	if (listEntry[1] == $line_tokens[2]) && (listEntry[2] == "bool") && ($insert_tree_flag == false) then
																		foundVar = true
																		break
																	elsif (listEntry[1] == $line_tokens[2]) && ((listEntry[2] == "bool tree") || (listEntry[2].split("[") == "bool tree")) && ($insert_tree_flag == true) then
																		foundVar = true
																		break
																	end
																end
																if (foundVar == false) then
																	abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Values for boolean trees are limited to \"true\" or \"false\".  Quitting compilation.")
																end
															end
	
															if (foundVar == true) && ($insert_tree_flag == false) then

#																puts "currentSubroutine|" + $currentSubroutine + "|"

																bool_assignment = bool_literal($line_tokens.last)
																if ($currentSubroutine != "") then
																	outputFile << $currentModuleName + "_" + subtoken[0] + "_node -> data = " + bool_assignment + ";\n\n"
																else
																	outputFile << subtoken[0] + "_node -> data = " + bool_assignment + ";\n\n"
																end
															elsif (foundVar == true) && ($insert_tree_flag == true) then

																if ($line_tokens[0].to_s.include? '[') then		# found array
																	$identifierList.each do |listEntry|
																		subtoken = $line_tokens[0].to_s.split('.')
									
																		if (listEntry[2].to_s.include? "array") then	# found array
																			# do something with arrays
																		else
																			# throw an error message
																		end
																	end
																else		# found tree
																	subtoken = $line_tokens[0].to_s.split('.')
							
																	numeric='0123456789'
									
#																	$identifierList.reject(&:empty?)

																	$identifierList.each do |listEntry|

																		if (listEntry[1] == subtoken[0]) && (listEntry[0] == "var") then
							
																			if (listEntry[2].include?('tree')) then
																				insert_node(listEntry)
																			else
																				abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Tree ranks must be integers, or blank.")
																			end
																		end
																	end
																end
									

															end

															outputFile.close
															break
														end
													end
												end
											end
		
										else
											abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found incorrect assignment syntax.  Tree node assignments require the syntax \"treename.node = value\".  Quitting compilation.")
										end
			
									else		# found assignment to an array or simple type

										foundMatch = false

										$identifierList.each do |listEntry|

											subtoken = $line_tokens[0].to_s.split('.')
		
											if (listEntry[0] == "var") && (listEntry[1] == $line_tokens[0]) then
												if (listEntry[2].to_s.include? "array") then	# found array
													# todo:  do something with arrays
													abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Arrays not supported yet.  Quitting compilation.")
												else
													if (listEntry[2] == 'bool') then	# found simple boolean
	
														currentStr = ""
														$line_tokens.each_with_index do |token, index|
															if (index == 2) then
																currentStr = token
															elsif (index > 2) then
																currentStr = currentStr + " " + token
															end
														end
	
	#													outputFile = File.open( "output.txt","a" )
														outputFile = File.open( "cache.txt","a" )
														currentStr_bool = bool_literal(currentStr)
														outputFile << "uint8_t _tmp" + ($tmpnum-1).to_s + " = " + currentStr_bool + ";\n"	# necessary for handling complicated boolean expressions
														outputFile << $currentModuleName + "_" + subtoken[0].to_s + "_node -> data = " + "_tmp" + ($tmpnum-1).to_s + ";\n\n"
														outputFile.close
														foundMatch = true
														break
#													elsif ((listEntry[2] == 'bool tree') || (listEntry[2].to_s.split('[').first == 'bool tree')) && ($line_tokens[2] == "null") then	# found boolean tree assignment to null
														outputFile = File.open( "output.txt","a" )
#														outputFile = File.open( "cache.txt","a" )
#														outputFile << "deltree_int08(&" + $line_tokens[0] + ", &_" + $line_tokens[0] + "_node, &_" + $line_tokens[0] + "_path);\n\n"
#														outputFile.close
#														foundMatch = true
#														break
													end
												end
											end
										end

										if (foundMatch == false) then
											abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found null assignment to an undeclared variable.  Quitting compilation.")
										end
									end
			
								elsif $line_tokens[1].to_s == "&" then	# found append/insert symbol


									if ($line_tokens[0].to_s.include? '[') then		# found array
										$identifierList.each do |listEntry|
											subtoken = $line_tokens[0].to_s.split('.')
		
											if (listEntry[2].to_s.include? "array") then	# found array
												# do something with arrays
											else
												# throw an error message
											end
										end
									else		# found tree
										subtoken = $line_tokens[0].to_s.split('.')

										numeric='0123456789'
		
										$identifierList.each do |listEntry|
		
											if (listEntry[1] == subtoken[0]) && (listEntry[0] == "var") then

												if (listEntry[2].include?('tree')) then
													insert_node(listEntry)
												else
													abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Tree ranks must be integers, or blank.")
												end
											end
										end
									end
		
								elsif $line_tokens[1].to_s == "->" then		# found walk symbol
		
									subtoken = $line_tokens[0].to_s.split('.')
									numeric='0123456789'
		
									$identifierList.each do |listEntry|
										checkEntry = listEntry[1].to_s.split('[')
		
		#								puts listEntry
		#								puts checkEntry[0].to_s
		#								puts subtoken[0].to_s
		
										if checkEntry[0].to_s == subtoken[0].to_s then
		
											if (numeric.include?(checkEntry[1].to_s[0...-1])) && (checkEntry[1].to_s[0...-1] != "0") then
												walk_tree($line_tokens[0].to_s, listEntry[1].to_s.split('[').last.to_s.chomp(']'))
											else
												abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Tree ranks must be integers, or blank.")
											end
		
										end
									end
		
								end
		
		
							end
		
		#					if a subroutine definition is found, call the subroutine handler
		#					if an exception handler definition is found, call the subroutine handler
		

							if myFile.eof? then
								myFile.close
								$fileList.delete($currentFileName)

								if ($currentModuleName == "main") then
									breakloop = true
								end

								break
							end

						end		# if ($mode == 'public') || ($mode == 'private')
		
						if $mode == 'beginning' then
							if $line_tokens[0] == 'module' then

								usingModules = true

								if $line_tokens[1] == $currentModuleName then
									$mode = 'imports'
								else
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Wrong module name specified; found " + $line_tokens[1].to_s + " but should have found " + $currentModuleName + ".")
								end

							elsif ($line_tokens[0].to_s == 'public') || ($line_tokens[0].to_s == 'private') || ($line_tokens[0].to_s == 'import') then
								abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The import statement, along with the public and private sections, may only be used in programs that are declared with the \"module\" keyword.  Quitting compilation.")
							elsif $line_tokens[0] == 'private' then
								$mode = 'private'
							elsif $line_tokens[0] == 'public' then
								$mode = 'public'
#							else
#								$mode = 'private'
							else
								if (usingModules == true) then
									abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Imported module formatted incorrectly.  Quitting compilation.")
								end
							end
		
						elsif $mode == 'imports' then
		
							if ($line_tokens[0].to_s == 'import') || ($line_tokens[0].to_s == 'limport') then
		
			#					check to see whether it's a reserved module name.  if so, update the module list.
			#					if not, turn the path into an absolute one and then check to see whether the module has already been added
			#					if limport:  call the literate function and replace the keyword with "import"
			#					if import:
			#						add to module list
			#						close the current file
			#						break

								if (skipImportCheck == false) then
	
									if ($line_tokens[1][0] != "`") || ($line_tokens[1][$line_tokens[1].length-1] != "`") || ($line_tokens[2] != "as") then
										abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found incorrect input file declaration.  Quitting compilation.")
									end
	
									foundMatch = false
									foundBadMatch = false
									$fileList.each do |hashEntry|
										if (hashEntry[0] == $line_tokens[1]) then
											foundMatch = true
											if (hashEntry[1] != $line_tokens[3]) then
												foundBadMatch = true
												break
											end
										end
									end
	
									if (foundBadMatch == true) then
										abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  Found match for module path, but the specified alias doesn't match.  Quitting compilation.")
									elsif (foundMatch == true) then
										# don't import modules that have already been handled
									else
										$line_tokens[1][0] = ""
										$line_tokens[1][$line_tokens[1].length-1] = ""
										$fileList[$line_tokens[1]] = $line_tokens[3]
									end

									$fileList.reverse_each do |key, value|
										myFile.close
										myFile=File.open(key,"r")
										$mode = "beginning"
										$currentFileName = key
										$currentModuleName = value
										break
									end

								end

							elsif inputline.strip == 'public' then
								$mode = 'public'
								skipImportCheck = true
							elsif inputline.strip == 'private' then
								$mode = 'private'
								skipImportCheck = true
							elsif $line_tokens[0].to_s.strip == "" then
								# do nothing on empty lines
							else
								abort("Error on line \"#{$currentLineNum.to_s}\" of module \"#{$currentModuleName.strip}\".  The second line of code must begin with \"import\", \"limport\", \"public\" or \"private\".  Quitting compilation.")
							end
						end
	
					end	

				else
					# do nothing with the current line

				end	# if ($multiLcomment == 0) && (fieldToStart < $line_tokens.length)

			end		# File.foreach(value).with_index do |inputline, line_num|

			fileStatus[$currentModuleName] = 'done'

			if ($currentSubroutine.nil? == false) && ($currentSubroutine != "") then
				abort("Error in module \"#{$currentModuleName.strip}\".  Found the end of a module before the current subroutine was closed.  Quitting compilation.")
			end

		elsif key == $fileList.keys[0] then	# we've finished processing all of the reachable modules
			breakloop = true				# this will break the outer loop

			foundMain = false
			$identifierList.each do |identifier|
				if (identifier[0] == "proc") && (identifier[1] == "main") then
					foundMain = true
					break
				end
			end

			if (foundMain == false) then
				abort("Error in module \"main\".  No \"main\" procedure defined.  Quitting compilation.")
			end

			if ($line_tokens[0].nil?) && ($currentSubroutine.nil? == false) then
				abort("Error in module \"#{$currentModuleName.strip}\".  Found the end of a module before the current subroutine was closed.  Quitting compilation.")
			end

			break
		end

	end		# $fileList.reverse_each do |key, value|

end

File.delete("cache.txt")