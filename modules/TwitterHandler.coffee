config = require("../config.json")
TwitterAPI = require("node-twitter-api")

class TwitterHandler

	options: {}

	twitter: null

	rateLimit:
		initialized: false
		user_timeline: 
			remaining: 180
			reset: parseInt(Date.now() / 1000)

	constructor: ->
		@twitter = new TwitterAPI
			consumerKey: config.twitterConsumerKey
			consumerSecret: config.twitterConsumerSecret
		
		@options =
			count: 200
			trim_user: true
			exclude_replies: true
			screen_name: ""

	_getTimeLine: (screenName, callback) =>
		options = JSON.parse(JSON.stringify(@options))
		options.screen_name = screenName

		@twitter.getTimeline "user_timeline", options, config.twitterAccessToken, config.twitterAccessTokenSecret, (err, tweets) =>
			@rateLimit.user_timeline.remaining--
			
			if err?
				console.log err
				tweets = []

			dates = []
			for tweet in tweets
				dates.push(new Date(tweet.created_at).getTime())

			console.log "Timeline for '#{screenName}' extracted (#{@rateLimit.user_timeline.remaining} remaining)."
			return callback?(null, dates)

	getTwitterDates: (screenName, callback) =>

		# check whether we have enough API calls left
		if @rateLimit.user_timeline.remaining == 0 or not @rateLimit.initialized

			@getRateLimit (err, status) =>
				if err?
					return callback?(err, null)

				@rateLimit.initialized = true
				@rateLimit.user_timeline = status

				# waiting until we got a new window
				waitingTime = @rateLimit.user_timeline.reset - parseInt(Date.now() / 1000) + 1

				if waitingTime < 0 or @rateLimit.user_timeline.remaining > 0
					waitingTime = 0

				if waitingTime > 0
					console.log "TwitterHandler.getTwitterDates(): waiting for #{waitingTime} seconds."

				setTimeout =>
					@getRateLimit (err, status) =>
						if err?
							return callback?(err, null)

						@rateLimit.user_timeline = status
						@_getTimeLine(screenName, callback)
				, waitingTime * 1000

		else
			return @_getTimeLine(screenName, callback)

	getRateLimit: (callback) =>
		@twitter.rateLimitStatus {}, config.twitterAccessToken, config.twitterAccessTokenSecret, (err, data) =>
			if err?
				return callback?(err, null)

			console.log "TwitterHandler.getRateLimit() called"

			return callback?(null, data.resources.statuses["/statuses/user_timeline"])

module.exports = TwitterHandler