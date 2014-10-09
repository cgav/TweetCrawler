TwitterHandler = require("modules/TwitterHandler")
CSVReader = require("modules/CSVReader")
Persister = require("modules/Persister")

persister = new Persister()
twitterHandler = new TwitterHandler()
allStartups = []

handleNextStartup = (callback) ->
	startup = allStartups.shift()

	if startup?
		twitterHandler.getTwitterDates startup.twitter, (err, dates) ->
			if err?
				return callback?(err, false)

			# persisting entry
			startup.twitter_dates = dates
			persister.update startup, (err) ->
				if err?
					return callback?(err, false)

				console.log "#{dates.length} tweets pulled from '#{startup.name}' handle"
				return handleNextStartup(callback)
	else
		return callback?(null, true)

injectToDB = ->
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

getTweets = ->
	persister.getAllStartups (err, startups) ->
		if err?
			console.log err.stack
			return

		console.log "#{startups.length} startup read from DB."
		allStartups = startups
		handleNextStartup (err, finished) ->
			if err?
				console.log err
				console.log err.stack
				persister.close()
				return

			if finished
				console.log "Done!"
				persister.close()
		
getTweets()