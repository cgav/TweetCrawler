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

	update: (startup, callback) =>
		@db.startups.update {name: startup.name}, {$set: startup}, (err, saved) =>
			if err? or not saved
				return callback?(err)

			return callback?(null)

	getAllByOffset: (offset, size, callback) =>

		# offset value is inclusive => skipping until (and inclusively) offset
		@db.startups.find({twitter_dates: {$exists: false}}).limit(size).skip offset, (err, startups) =>
			if err?
				return callback?(err, null)

			names = []
			for startup in startups
				names.push 
					name: startup.name
					twitter: startup.twitter

			if callback?(null, names) and names.length > 0
				@getAllByOffset(offset + size, size, callback)

	getAllStartups: (callback) =>
		startups = []
		@getAllByOffset 0, 1000, (err, newStartups) =>
			if err?
				return callback?(err, null)

			startups = startups.concat(newStartups)

			# get more startups
			if newStartups.length > 0
				return true

			callback?(null, startups)
			return false

	close: =>
		@db.close()

module.exports = Persister