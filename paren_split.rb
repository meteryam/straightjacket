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