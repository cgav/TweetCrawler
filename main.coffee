TwitterHandler = require("modules/TwitterHandler")

twitterHandler = new TwitterHandler()
twitterHandler.getTweetDates "jason", (err, dates) ->
	if err?
		console.log err
		return

	twitterHandler.getTweetDates "mymundus", (err, dates) ->
		if err?
			console.log err
			return
