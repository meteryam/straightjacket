#!/usr/bin/python3

# -*- coding: utf-8 -*-

# This literate programming tool copies out-of-order source code from a text file and writes it in-order to another text file.  Its purpose is to assist programmers who wish to use the literate programming approach using plain text instead of TeX.

# The module looks for text located between tags formatted like this:  <<tagName>>

# It exports the text it finds into temporary files and then re-assembles the contents of those files in order.  To define the proper output order, the program first looks for a list of tags (without brackets) surrounded by <<def>> and <</def>> tags.  The final output will contain text from each declared tag, in the order given by the tag list within the <<def>> section.  The program will give an error and quit if a tag is not used, if an undeclared tag is used, if a tag is misspelled or if a section of text begins with one tag but is ended by another tag.  Tags are case-insensitive, they may not contain spaces and they may not be indented by tabs.

# Input example:

# <<def>>
# <<user_defined_tag>>
# <</def>>

# <<user_defined_tag>>
# arbitrary code written here
# <</user_defined_tag>>

# write some argument-handling code to allow this to be used as a standalone module

def code_extract( literateFile ):
	print("processing file " + literateFile)
	
	mode = "TEXT"
	
	myOpenFileHandle = open(literateFile, "r")
	
	lineNumber = 0
	tagList = []
	
	for eachLine in myOpenFileHandle:
		
		workingLine = eachLine.rstrip()
		
		lineNumber = lineNumber + 1
		
		if(mode == "TEXT"):
			
			# print(workingLine)
			
			if(workingLine == "<<def>>"):
				mode = "COLLECT_TAGS"
				
		elif(mode == "COLLECT_TAGS"):
			
			if(workingLine == "<</def>>"):
				mode = "FIND_CODE"
			elif ((workingLine[:2] == "<<") and (workingLine[-2:] == ">>")):
				
				workingLine2 = workingLine[2:]
				workingLine3 = workingLine2[:-2]
				
				print(str(lineNumber) + ": " + workingLine3)
				
				appendTag = "TRUE"
				for eachTag in tagList:
					if eachTag == workingLine3:
						appendTag = "FALSE"
				if (appendTag == "TRUE"):
					tagList.append(workingLine3)
				
		elif(mode == "FIND_CODE"):
			
			# when a recognized tag is found, set mode to EXTRACT_CODE
			
			if ((workingLine[:2] == "<<") and (workingLine[-2:] == ">>")):
				
				workingLine2 = workingLine[2:]
				workingLine3 = workingLine2[:-2]
				
				foundTag = "FALSE"
				for eachTag in tagList:
					if eachTag == workingLine3:
						foundTag = "TRUE"
						currentTag = workingLine3
				if (foundTag == "TRUE"):
					mode = "EXTRACT_CODE"
					
					# open snippet file
					
					currentSnippetName = "tmp/" + foundTag + ".txt"
					currentSnippetFileHandle = open(currentSnippetName, "a")
					

					
			
		elif(mode == "EXTRACT_CODE"):
			
			# when a proper close tag is found, set mode to FIND_CODE
			
			if ((workingLine[:3] == "<</") and (workingLine[-2:] == ">>")):
				
				workingLine2 = workingLine[3:]
				workingLine3 = workingLine2[:-2]
				
				close(currentSnippetFileHandle)

				if (currentTag == workingLine3):
					mode = "FIND_CODE"
					
				else:
					
					print("Wrong tag found.  Exiting.")
					sys.exit(1)
					
					
			else:
			
				# append lineNumber and append lines to snippet file
				
				print(str(lineNumber) + ": " + eachLine)
				currentSnippetFileHandle.write(str(lineNumber) + ": " + eachLine)
		
		# print(str(lineNumber) + ": " + eachLine)
		
	close(currentSnippetFileHandle)
	close(myOpenFileHandle)
	
	# concatenate snippets in order
	
	temporaryOutputFileName = "tmp/_" + literateFile
	temporaryOutputFileHandle = open(temporaryOutputFileName, "a")
	
	for eachSnippet in tagList:
		myOpenFileHandle = open(eachSnippet, "r")
		for eachLine in myOpenFileHandle:
			temporaryOutputFileHandle.write(eachLine)
		
		close(myOpenFileHandle)
	
	close(temporaryOutputFileHandle)

	return temporaryOutputFileHandle