# Copyright Vladimir Andreev

#

class Service
	# Object constructor

	constructor: (client) ->
		@_client = client

	#

	_outputHandler: (callback) -> (error, payload) ->
		return if typeof callback isnt 'function'

		if error?
			callback(error)
		else if payload.result is 'reject'
			error = new Error(payload.reason)
			callback(error)
		else
			callback(null, payload)

		return

	#

	accountBalance: (callback) ->
		@_client.invokeMethod('balance', null, @_outputHandler(callback))

		@

	#

	senderList: (callback) ->
		@_client.invokeMethod('senders', null, @_outputHandler(callback))

		@

	#

	addSender: (name, callback) ->
		@_client.invokeMethod('sign', sign: name, @_outputHandler(callback))

		@

	#

	sendMessage: (options, callback) ->
		@_client.invokeMethod('send', options, callback)

		@

	#

	messageStatus: (id, callback) ->
		@_client.invokeMethod('status', id: id, @_outputHandler(callback))

		@

# Exported objects

module.exports = Service
