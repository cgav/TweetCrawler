config = require("../config.json")
mongodb = require("mongojs")
When = require("when")

class Persister
	
	db: null

	constructor: ->
		@db = mongodb.connect config.dbName, ["startups"]

		@db.startups.getIndexes (err, indexes) =>
			if err?
				return

			for index in indexes
				if "name" in index.key
					return

			# create index
			@db.startups.ensureIndex({ name: 1 }, { unique: true })	

	insert: (startups, callback) =>
		dfds = []
		persistCount = 0
		droppedCount = 0

		for startup in startups
			do (startup) =>
				dfd = When.defer()
				dfds.push(dfd.promise)

				@db.startups.save startup, (err, saved) =>
					if err? or not saved
						droppedCount++
						dfd.resolve()
						return

					persistCount++
					dfd.resolve()

		When.all(dfds).then =>
			return callback?(null, persistCount, droppedCount)

	close: =>
		@db.close()

module.exports = Persister