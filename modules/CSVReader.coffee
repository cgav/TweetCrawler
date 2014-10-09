fs = require("fs")

class CSVReader
	
	filename: null

	constructor: (filename) ->
		@filename = filename

	extractToken: (token) ->
		if not token or token?.length == 0
			return ""

		return token[1...token.length - 1]

	parseLine: (line) =>
		tokens = line.split(";")
		entry =
			name: @extractToken(tokens[0])
			twitter: @extractToken(tokens[1])
			description: @extractToken(tokens[2])
			urls: @extractToken(tokens[3])
			founders: @extractToken(tokens[4]).split(",")

		return entry

	getLines: (callback) =>
		fs.readFile @filename, (err, data) =>
			if err?
				return callback?(err, null)

			lines = data.toString().split("\r\n")
			parsedLines = []
			for line in lines[1..]
				parsedLines.push(@parseLine(line))

			return callback?(null, parsedLines)


module.exports = CSVReader