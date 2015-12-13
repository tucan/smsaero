# Copyright Vladimir Andreev

# Required modules

HTTP = require('http')
HTTPS = require('https')

Crypto = require('crypto')
Iconv = require('iconv-lite')
QS = require('qs')

# SMSAero client

class Client
	# Connection default parameters

	SERVER_PROTO = 'http'

	SERVER_NAME = 'gate.smsaero.ru'

	SERVER_PLAIN_PORT = 80
	SERVER_SECURE_PORT = 443

	# Request and response default parameters

	REQUEST_CHARSET = 'utf-8'

	# Object constructor

	constructor: (options) ->
		options ?= Object.create(null)

		@_proto = options.proto ? SERVER_PROTO

		@_HTTP = if @_proto is 'http' then HTTP else HTTPS

		@_host = options.host ? SERVER_NAME
		@_port = options.port ? if @_proto is 'http' then SERVER_PLAIN_PORT else SERVER_SECURE_PORT

		@_charset = options.charset ? REQUEST_CHARSET

		@_user = options.user
		@_hash = Crypto.createHash('md5').update(options.password).digest('hex')

	# Generates request options based on provided parameters
 
	_requestOptions: (name, blob) ->
		path = '/' + name + '/'

		headers =
			'Content-Type': 'application/x-www-form-urlencoded; charset=' + @_charset
			'Content-Length': blob.length

		options =
			host: @_host, port: @_port
			method: 'POST', path: path
			headers: headers

		options

	# Generates onResponse handler for provided callback

	_responseHandler: (callback) -> (response) =>
		# Array for arriving chunks

		chunks = []

		# Assign necessary event handlers

		response.on('readable', () ->
			chunks.push(response.read())

			return
		)

		response.on('end', () ->
			return if typeof callback isnt 'function'

			blob = Buffer.concat(chunks)

			# Handle status code

			firstDigit = response.statusCode // 100

			switch firstDigit
				when 2
					output = JSON.parse(Iconv.decode(blob, 'utf-8') or '{}')
					callback(null, output)
				else
					callback(new Error('Unexpected status code'))

			return
		)

		return

	# Generates onError handler for provided callback

	_errorHandler: (callback) -> (error) =>
		callback?(error)

		return

	# Invokes pointed method on the remote side

	invokeMethod: (name, input, callback) ->
		fullInput = Object.create(null)

		fullInput.answer = 'json'
		fullInput.user = @_user
		fullInput.password = @_hash

		fullInput[key] = value for key, value of input

		# Make serialization and derived text encoding

		blob = Iconv.encode(QS.stringify(fullInput), @_charset)

		# Create request using generated options

		request = @_HTTP.request(@_requestOptions(name, blob))

		# Assign necessary event handlers

		request.on('response', @_responseHandler(callback))
		request.on('error', @_errorHandler(callback))

		# Write body and finish request

		request.end(blob)

		@

# Exported objects

module.exports = Client
