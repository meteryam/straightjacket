#!/usr/bin/python3

# -*- coding: utf-8 -*-

import sys, getopt

import sjLiterate, sjControl

# If the main file is a literate file, then the compiler should process it accordingly.  The straightjacket compiler uses the command line argument -l to designate the main module as a literate module.

sys.argv = sys.argv[1:]

number_of_args = len(sys.argv)

print("Number of arguments: " + str(number_of_args))

if number_of_args == 2:
	if sys.argv[0] == '-l' or sys.argv[0] == '--literate':
		# print(sys.argv[0])
		literateFlag = 1
		bareCodeFileName = sjLiterate.code_extract(sys.argv[1])
		
elif number_of_args == 1:
	if sys.argv[0] == '-l' or sys.argv[0] == '--literate':
		print("missing file name. exiting.")
		sys.exit(1)
	else:
		literateFlag = 0
		bareCodeFileName = sys.argv[0]
	
else:
	print("wrong number of arguments supplied.")
	sys.exit(1)

print("file name to process: " + bareCodeFileName)

# verify that the supplied filenaamme exists

modulesList = []
processedModulesList = []

# add bareCodeFileName to modulesList

# print(bareCodeFileName)

# format:  module alias;literate flag[0|1];module path;module path where alias applies
firstModuleEntry = 'main;' + str(literateFlag) + ';' + bareCodeFileName + ';'



# modulesList.append(bareCodeFileName)

modulesList.append(firstModuleEntry)


# print(len(modulesList))

# loop through modulesList

endChunk = 1		# terminate chunk
braceCount = 0
parenCount = 0
bracketCount = 0
backTickCount = 0
enclosedCount = 0

# for eachModule in modulesList:
while True:
	
	# aliasList = []
	
	# print(eachModule)

	lineNumber = 0
	
	# open module file
	
	mode = 0		# importModule
	
	lastModuleNumber = len(modulesList) - 1
	
	# print(lastModuleNumber)
	
	myOpenFileEntry = modulesList[lastModuleNumber]
	myOpenFile = myOpenFileEntry.split(';')[2]
	myOpenFileHandle = open(myOpenFile, "r")
	currentModule = myOpenFileEntry.split(';')[0]
	
	importModule = 0
	
	# print(myOpenFile)
	
	####################
	# tokenize each line #
	####################
	
	extractMode = 0	# keyword
	# lineChunks = []
	multiLine = 0
	snippet = []
	
	for eachLine in myOpenFileHandle:
		
		if (extractMode == 0):
			# lineChunks = []
			charList = []
			
		if (endChunk == 1):
			#if (len(lineChunks) > 0):
			#	print(lineChunks)
			lineChunks = []

			
		if multiLine == 0:
			snippet = []
			braceCount = 0
			parenCount = 0
			bracketCount = 0
			
		charCount = 0
		
		
		if eachLine != '':
			currentLine = eachLine.strip()
		
			for eachCharacter in currentLine:
				
				# charCount = charCount + 1
				
				appendCharFlag = 0
				
			
				# detect and exclude comments
				
				# single-line comments start with hash marks:  #
				# multi-line comments are enclosed by these characters:  /# #/
				
				if  extractMode == 0:	# keyword
					
					if ( (len(charList) > 0) and ((charList[-1] != '\\') or (charList[-1] == '/')) ) or (len(charList) == 0):
					
						# print('here i am')
					
						if  eachCharacter == '#':
							
							# print('here i am')
							
							#if (len(charList) > 0):
								#charList.pop()
							# break
					
							# handle multi-line comments
							
							if (len(charList) > 0):
								
								if (charList[-1] == '/'):
									extractMode = 1	# comment
									
									charList.pop()
									# break
									
									# print("here i am")
									
								#else:
									#charList.pop()
									
							#else:
								
							break
						
						elif (eachCharacter == '('):
						
							parenCount = parenCount + 1
							extractStr = "".join(charList).strip()
							charList.clear()
							
							charList.append(eachCharacter)
							
							if (extractStr != ''):
								lineChunks.append(extractStr)

							# extractMode = 2	# subroutine arguments
							
							parenCount = parenCount + 1
							lineChunks.append('(')
							charList.clear()
							
							multiLine = 1
						
						#else:
							
						#	appendCharFlag = 1
						#	eachCharacter.lower()
							
							
						elif (eachCharacter == ')'):
							
							# print("here i am")

						
							parenCount = parenCount - 1
							extractStr = "".join(charList).strip()
							# charList.clear()
							
							# charList.append(eachCharacter)
							
							if (extractStr != ''):
								lineChunks.append(extractStr)

							# extractMode = 2	# subroutine arguments
							
							parenCount = parenCount + 1
							lineChunks.append(')')
							# charList.clear()
							# print(lineChunks)
							
						# handle array literals
								
						elif (eachCharacter == '['):
						
							bracketCount = bracketCount + 1
							extractStr = "".join(charList).strip()
							charList.clear()
							
							charList.append(eachCharacter)
							
							if (extractStr != ''):
								lineChunks.append(extractStr)
							
							bracketCount = bracketCount + 1
							lineChunks.append('[')
							charList.clear()
							
							multiLine = 1
							
						elif (eachCharacter == ']'):

						
							bracketCount = bracketCount - 1
							extractStr = "".join(charList).strip()
							
							if (extractStr != ''):
								lineChunks.append(extractStr)
							
							bracketCount = bracketCount + 1
							lineChunks.append(']')
							
						# handle list literals
								
						elif (eachCharacter == '{'):
						
							braceCount = braceCount + 1
							extractStr = "".join(charList).strip()
							charList.clear()
							
							charList.append(eachCharacter)
							
							if (extractStr != ''):
								lineChunks.append(extractStr)
							
							braceCount = braceCount + 1
							lineChunks.append('{')
							charList.clear()
							
							multiLine = 1
							
						elif (eachCharacter == '}'):

						
							braceCount = braceCount - 1
							extractStr = "".join(charList).strip()
							
							if (extractStr != ''):
								lineChunks.append(extractStr)
							
							braceCount = braceCount + 1
							lineChunks.append('}')
							
	#					elif (eachCharacter == '{'):
						
	#						braceCount = braceCount + 1
	#						extractStr = "".join(charList).strip()
	#						charList.clear()
							
	#						charList.append(eachCharacter)
	#						eachCharacter = ''
							
	#						if (len(extractStr) > 0):
	#							lineChunks.append(extractStr)

	#						extractMode = 3	# list
							
						# handle strings
							
						elif (eachCharacter == '`'):
						
							extractStr = "".join(charList).strip()
							charList.clear()
							
							charList.append(eachCharacter)
							eachCharacter = ''
							
							if (len(extractStr) > 0):
								lineChunks.append(extractStr)
								
							backTickCount = backTickCount + 1

							extractMode = 4	# string
							
							multiLine = 1
							
						# ignore whitespace
							
						elif (eachCharacter == ' ') or (eachCharacter == '\t'):
						
							extractStr = "".join(charList).strip()
							charList.clear()
							
							eachCharacter = ''
							
							if (len(extractStr) > 0):
								lineChunks.append(extractStr)

							extractMode = 0	# string
							
						elif (charCount >= len(currentLine) -1):
							charList.append(eachCharacter)
							extractStr = "".join(charList).strip()
							charList.clear()
							if (len(extractStr) > 0):
								lineChunks.append(extractStr)
								
						else:
							
							appendCharFlag = 1
							eachCharacter.lower()
							
					# elif (charCount == len(currentLine)):
						# lineChunks.append(extractStr)
						
				elif (extractMode == 1):	# comment
					
					# print("here i am")
					
					lastChar = charCount - 1

					if (charCount > 0) and (eachLine[lastChar] == '#') and (eachCharacter == '/'):
					
						eachCharacter = ""
						extractMode = 0	# keyword
						#print('here i am')
						#print(charList)
						# break
						
						
#				elif (extractMode == 2):	# subroutine arguments
					
#					appendCharFlag = 1
					
#					if (eachCharacter == '(') and (charList[-1] != '/'):
#						parenCount = parenCount + 1
#					elif (eachCharacter == ')') and (charList[-1] != '/'):
#						parenCount = parenCount - 1
						
#					if parenCount == 0:
#						extractMode = 0	# keyword
						
#						charList.append(eachCharacter)
#						parenStr = "".join(charList).strip()
#						charList.clear()
#						eachCharacter = ''
						
#						if (len(parenStr) > 0):
#							lineChunks.append(parenStr)
						
#				elif (extractMode == 3):	# list
					
#					appendCharFlag = 1
					
#					if (eachCharacter == '{'):
#						braceCount = braceCount + 1
#					elif (eachCharacter == '}'):
#						braceCount = braceCount - 1
						
#					if braceCount == 0:
#						extractMode = 0	# keyword
						
#						charList.append(eachCharacter)
#						listStr = "".join(charList).strip()
#						charList.clear()
#						eachCharacter = ''
						
#						if (len(listStr) > 0):
#							lineChunks.append(listStr)
							
				elif (extractMode == 4):	# string
					
					appendCharFlag = 1
					
					if (eachCharacter == '`') and (charList[-1] != '/'):
						
						backTickCount = backTickCount - 1

						extractMode = 0	# keyword
						
						charList.append(eachCharacter)
						stringStr = "".join(charList).strip()
						charList.clear()
						eachCharacter = ''
						
						if (len(stringStr) > 0):
							lineChunks.append(stringStr)
							multiLine = 0
							
					# elif (charCount == len(currentLine)):
						# lineChunks.append(extractStr)
					
				if (appendCharFlag == 1):
					
					if (extractMode == 0):
						charList.append(eachCharacter.lower())
					else:
						charList.append(eachCharacter)
						
				# elif (charCount >= len(currentLine)):
					# lineChunks.append(extractStr)
				
				charCount = charCount + 1
			
				
		# only wrap up our chunks if we're finished with every chunk, each of which might span multiple lines
		enclosedCount = braceCount + parenCount + bracketCount + backTickCount
		

			
		# if  (len(charList) > 0) and ((extractMode == 0) or (enclosedCount == 0)):		# keyword
		if  (len(charList) > 0) and (enclosedCount == 0):		# keyword
			
			finalStr = "".join(charList).strip()
			charList.clear()
			
			if (len(finalStr) > 0):
				lineChunks.append(finalStr)
		
				# print(lineChunks)
			
		# track lineNumber

		if myOpenFileEntry.split(';')[1] == '1':		# if literate module
		
			lineNumber = lineChunks[0]
			
			lineChunks.pop(0)
			
		else:
		
			lineNumber = lineNumber + 1
		
		###################
		# import modules #
		###################
		
		# if mode == 0:		# importModule

		# import `libraryName` as aliasName					// import library as aliasName
											# in order for the resulting code to work, the module's alias
											# must match the alias used within the module itself.
											# the aliasName must also contain no whitespace.
		# limport `libraryName` as aliasName													// import literate library
		
		# format:  module alias;literate flag[0|1];module path;module path where alias applies
	
		if (len(lineChunks) > 1) and ((lineChunks[0] == 'limport') or (lineChunks[0] == 'import')):
		
			if (lineChunks[0] == 'limport'):
				newModuleLiterateFile =  1
			
				# newModule = straightjacket.py(lineChunks[1])
				
				print("this feature hasn't fully been implemented yet.  exiting.")
				sys.exit(1)
				
			else:
		
				
				newModuleLiterateFile =  0
				# print(newModule)
			
				if (len(lineChunks) == 5) and (lineChunks[2] == 'as') and (lineChunks[3] == 'alias'):
					newAlias = lineChunks[4].strip('`')
				elif (len(lineChunks) > 2) and (len(lineChunks) != 5):
					print("wrong number of arguments for import statement.  exiting.")
					sys.exit(1)
				else:
					newAlias = ''
				
				newModule = lineChunks[1].strip('`')
				if (newAlias == ''):
					testModuleEntry = newAlias + ';' + str(newModuleLiterateFile) + ';' + newModule + ';'
				else:
					testModuleEntry = newAlias + ';' + str(newModuleLiterateFile) + ';' + newModule + ';' + myOpenFile
					
				# print(testModuleEntry)
				# sys.exit(0)
			
				# look for duplicates
				
				foundDup = 0
				for moduleListEntry in modulesList:
					# print(moduleListEntry)
					if (moduleListEntry == testModuleEntry):
						foundDup = 1
					
				alreadyImported = 0
				for processedModuleListEntry in processedModulesList:
					# print(processedModuleListEntry)
					if (processedModuleListEntry == testModuleEntry):
						foundDup = 1
						
					processedModulePath = processedModuleListEntry.split(';')[2]
					if (processedModulePath == newModule):
						alreadyImported = 1
						
				if (foundDup == 0):
					
					# nop = 1
					
					# print("here i am")

					modulesList.append(testModuleEntry)
					processedModulesList.append(testModuleEntry)
					# print(modulesList)
					
					myOpenFileHandle.close()
					nextFileEntry = modulesList[lastModuleNumber]
					nextOpenFile = myOpenFileEntry.split(';')[2]
					myOpenFileHandle = open(nextOpenFile, "r")
					
					
					if (alreadyImported == 0):
						importModule = 1
					
					break
				
			# print('here i am')
			
		elif (len(lineChunks) > 0) and (lineChunks[0] == 'module'):
		
			mode = 1		# body
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			exportFlag = 0
			forwardFlag = 0
			
			if (len(lineChunks) > 0):
				
				# handle and remove "export" chunk
				
				if (lineChunks[0] == 'export'):
					exportFlag = 1
					lineChunks.pop(0)
					
					# throw error if we're in the main module
					if (currentModule == 'main'):
						print('Nothing can be exported from the main module.  Aborting.')
						sys.exit(1)
					
					
					
					
					
				# handle and remove "forward" chunk
				
				if (len(lineChunks) > 0) and (lineChunks[0] == 'forward'):
					forwardFlag = 1
					lineChunks.pop(0)
					
					
				# oops, the input line contained only export and/or forward!
					
				if (len(lineChunks) == 0):
					print('Found incomplete line.  Exiting.')
					sys.exit(1)
				
				
				# handle variable declarations
				# may eventually need to handle multi-line declarations
				
				if (lineChunks[0] == 'var'):
					
					# error on forward flag
					
					if (forwardFlag == 1):
						print('Forward declarations can only be used with subroutines.  Aborting.')
						sys.exit(1)
					
					multiLine = 0
					snippet.append(lineChunks)
					
					# cOutput = sjVarDeclaration.defVariable(snippet)
					
					
				
				# handle function definitions
				# only exported subroutines can be called from other modules
				# exports not allowed from the main module
				
					# export forward func foo( typeName ) return typeName
					
					# func foo( typeName variableName ) return typeName
					# end func foo
				
				elif (lineChunks[0] == 'func'):
					if (forwardFlag == 0):
						multiLine = 1
						snippet.append(lineChunks)
					
						
				#elif ((lineChunks[0] == 'forward') and (lineChunks[1] == 'func')) or ((lineChunks[0] == 'export') and (lineChunks[1] == 'forward') and (lineChunks[2] == 'func')):
					else:
						multiLine = 0
						snippet.append(lineChunks)
							
					cOutput = sjControl.defSubroutine(1,snippet,exportFlag,forwardFlag)
					print(cOutput)
				
				
				# handle procedure definitions
				# only exported subroutines can be called from other modules
				# cannot be called from functions
				
					# export forward proc foo( typeName )
					
					# proc foo( typeName variableName )
					# end proc foo
				
				elif (lineChunks[0] == 'proc'):
					if (forwardFlag == 0):
						multiLine = 1
						snippet.append(lineChunks)

						
				#elif ((lineChunks[0] == 'forward') and (lineChunks[1] == 'proc')) or ((lineChunks[0] == 'export') and (lineChunks[1] == 'forward') and (lineChunks[2] == 'proc')):
					else:
						multiLine = 0
						snippet.append(lineChunks)
							
					cOutput = sjControl.defSubroutine(2,snippet,exportFlag,forwardFlag)
					print(cOutput)
				
				# handle main subroutine
				# cannot be called from another subroutines
				# error on export flag
				# error on forward flag
				
					# main()
					# end main
					
					# main( typeName variableName ) returns typeName
					# end main
				
				elif (lineChunks[0] == 'main'):
				
					multiLine = 1
					snippet.append(lineChunks)
					
					
					
				elif (multiLine == 1):
					snippet.append(lineChunks)
				
					if (len(lineChunks) == 2) and (lineChunks[0]  == 'end') and (lineChunks[1]  == 'main'):
						endChunk = 1
						multiLine = 0
						
						cOutput = sjControl.defSubroutine(3,snippet,exportFlag,forwardFlag)
						print(cOutput)
						
						
						
				# handle custom types
				
				# handle custom type conversions
						
				# handle expressions
				
				# cOutput = sjExpressons(snippet)
					
				else:
					
					print(lineChunks)
			
			
			# elif (extractMode == 0) and (enclosedCount == 0):
				# endChunk = 1
			
			
		# else:
			
			# print(lineChunks)
			
				
	if (importModule == 0):
		modulesList.pop()


	if len(modulesList) == 0:
		break
	



