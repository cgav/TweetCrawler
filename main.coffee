TwitterHandler = require("modules/TwitterHandler")
CSVReader = require("modules/CSVReader")
Persister = require("modules/Persister")

# twitterHandler = new TwitterHandler()
# twitterHandler.getTweetDates "jason", (err, dates) ->
# 	if err?
# 		console.log err
# 		return

csvReader = new CSVReader("res/twitter_all.csv")
csvReader.getLines (err, startups) ->
	if err?
		console.log err
		return

	persister = new Persister()
	persister.insert startups, (err, persistCount, droppedCount) ->
		if err?
			console.log err
			return

		console.log "#{persistCount} entries persisted, #{droppedCount} entries dropped."
		persister.close()