
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

=begin

If the main file is a literate file, then the compiler needs to process it accordingly.  The compiler uses the command line argument -l to determine this.

This literate programming tool copies out-of-order source code from a text file and writes it in-order to another text file.  Its purpose is to assist programmers who wish to use the literate programming approach using plain text instead of TeX.

The program looks for text located between tags formatted like this:  <<tagName>>

It exports the text it finds into temporary files and then re-assembles the contents of those files in order.  To define the proper output order, the program first looks for a list of tags (without brackets) surrounded by <<def>> and <</def>> tags.  The final output will contain text from each declared tag, in the order given by the tag list within the <<def>> section.  The program will give an error and quit if a tag is not used, if an undeclared tag is used, if a tag is misspelled or if a section of text begins with one tag but is ended by another tag.  Tags are case-insensitive, they may not contain spaces and they may not be indented by tabs.

=end

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

def literate(filename)

	processing = 'begin'
	taglist = Array[]
	deftag = '<<def>>'
	defendtag = '<</def>>'
	openfilename = ''

	File.foreach(filename).with_index do |inputline, line_num|

		linecount = line_num.to_i + 1

		if processing == 'begin' then

			if inputline.strip == '<<def>>' then 
				processing = 'collect'
			end

		elsif processing == 'collect' then

			if inputline.strip == '<</def>>' then
				processing = 'search'
			else

				taglist.each do |tag|
					if inputline.strip == tag then
						abort("Found duplicate tag \"#{inputline.strip}\" on line number \"#{linecount.to_s.strip}\" of file \"#{filename.strip}\".  Quitting compilation.")
					end
				end

				taglist.push(inputline.strip)
			end

		elsif processing == 'search' then
			taglist.each do |tag|

				fulltag = '<<' + tag + '>>'
				endtag = '<</' + tag + '>>'

				if inputline.strip == fulltag then

					tempfilename ='C:\temp\sj\literate\\' + tag + '.txt'
					if File.exists?(tempfilename) == false then FileUtils.touch(tempfilename) end
					openfilename = tempfilename
					processing = 'extract'

				elsif inputline.strip == endtag then
					abort("Found end tag while searching for beginning tag on line number \"#{linecount.to_s.strip}\" of file \"#{filename.strip}\".  Quitting compilation.")
				end

			end
		elsif processing == 'extract' then
			taglist.each do |tag|

				fulltag = '<<' + tag + '>>'
				endtag = '<</' + tag + '>>'

				if inputline.strip == fulltag then

					abort("Found beginning tag while extracting existing tag on line number \"#{linecount.to_s.strip}\" of file \"#{filename.strip}\".  Quitting compilation.")

				elsif inputline.strip == endtag then
					processing = 'search'

				end

			end

			outputline = line_num.to_s + "\t" + inputline

			if processing == 'extract' then File.open(openfilename, "a") {|f| f.write(outputline) } end


		end

	end

	# append all of the files in order

	basename = File.basename filename
	extractedfilename = 'C:\temp\sj\\' + Time.new.strftime("%Y%m%d%H%M%S") + basename
	FileUtils.touch(extractedfilename)

	taglist.each do |tag|

		tempfilename ='C:\temp\sj\literate\\' + tag + '.txt'
		File.foreach(tempfilename).with_index do |inputline|
			File.open(extractedfilename, "a") {|f| f.write(inputline) }
		end

		FileUtils.rm(tempfilename)

	end

	return extractedfilename
end


# if the literateflag is true, apply the literate procedure to the input file.  also set the main module's status in a special hash table.

fileStatus = Hash.new()

if literateflag == true then 
	$currentFileName = literate(filename)
	fileStatus["main"] = "literate"
else
	$currentFileName = filename
	fileStatus["main"] = "illiterate"
end


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


# define tokenization procedure in case we need it

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


# define paren_split procedure in case we need it

def paren_split(line)

	tempnum = 0

	line_array = Array[]
	subStr = ""
	leftPnum = 0
	rightPnum = 0
	status = "normal"
	offset = 0
	currentEntry = 0

	if line[0] == "(" then
		offset = 1
	end

	i = 0
	while i < line.length do

		if line[i] == "(" then
			leftPnum = leftPnum + 1
		elsif line[i] == ")" then
			rightPnum = rightPnum + 1
		end

		if status == "normal" then

			if line[i] == "`" then
				status = "string"
			elsif (line[i] == "(") && (i != 0) then
				$tempnum = $tempnum + 1
				subStr = subStr + "_tmp" + tempnum.to_s + " "
				line_array[currentEntry] = subStr
				subStr = line[i]
				currentEntry = tempnum
			elsif (line[i] == ")") && (i != 0) then
				subStr = subStr + line[i]
				subStr.strip!
				line_array[currentEntry] = subStr
				currentEntry = leftPnum - rightPnum - offset
				subStr = line_array[currentEntry]
			else
				subStr = subStr + line[i]
#				puts subStr
			end
		end

#		printf line[i]
		i = i + 1
	end

	if line[line.length-1].to_s != ")" then
		subStr.strip!
		line_array[currentEntry] = subStr
		currentEntry = leftPnum - rightPnum - offset
	end

#	puts
#	printf "line_array: "
#	puts line_array
#	puts

	return line_array
end


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


# boolean assignment handler

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

# define procedure to walk down the tree, one node at a time

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



# handle subroutine declarations (forward or otherwise)

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

##########################
# handle procedure calls #
##########################

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


#########################
# check function calls #
#########################

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

####################
### main program ###
####################


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