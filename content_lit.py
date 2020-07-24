"""

GPL v3:

The straightjacket copiler translates code written in the straightjacket
programming language to c code.
Copyright (C) 2020 Jessica Richards

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

Notes:

I wrote this module in Ruby two years ago.  It works perfectly well (as did the Pascal version I wrote in 2012), but I'll probably rewrite it in Python.  We'll see.



"""


:literate_handler

	# extract and re-arrange literate content
	# print line numbers in output file

	If the main file is a literate file, then the compiler needs to process it accordingly.  The compiler uses the command line argument -l to determine this.

	This literate programming tool copies out-of-order source code from a text file and writes it in-order to another text file.  Its purpose is to assist programmers who wish to use the literate programming approach using plain text instead of TeX.

	The program looks for text located between tags formatted like this:  <<tagName>>

	It exports the text it finds into temporary files and then re-assembles the contents of those files in order.  To define the proper output order, the program first looks for a list of tags (without brackets) surrounded by <<def>> and <</def>> tags.  The final output will contain text from each declared tag, in the order given by the tag list within the <<def>> section.  The program will give an error and quit if a tag is not used, if an undeclared tag is used, if a tag is misspelled or if a section of text begins with one tag but is ended by another tag.  Tags are case-insensitive, they may not contain spaces and they may not be indented by tabs.

	# ruby version:

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
	
		
end literate_handler
