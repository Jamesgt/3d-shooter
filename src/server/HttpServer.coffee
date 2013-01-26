http = require 'http'
fs = require 'fs'

fs.isDir = (path) ->
	(fs.lstatSync path).isDirectory()

fs.getExtension = (path) ->
	(path.split '.').pop()

class HttpServer
	constructor: (@root, @ip, @port) ->
		@PID_FILE = 'server/pid.txt'
		@mimeMap = {
			'js': 'text/javascript'
			'css':  'text/CSS'
			'html': 'text/html'
			'png':  'image/png'
		}
		@defaultMimeType = 'text/plain'

	start: ->
		if fs.existsSync @PID_FILE
			pid = fs.readFileSync @PID_FILE
			try
				process.kill pid
				console.log "Stopped process: #{pid}."

		fs.writeFileSync @PID_FILE, process.pid

		@server = http.createServer @requestHandler
		@server.on 'listening', =>
			console.log "Server (#{process.pid}) running at #{@ip}:#{@port}/"
		@server.on 'error', (error) =>
			console.log "#{error}, trying again in 100ms..."
			@listen()
		
		@listen()

	listen: ->
		setTimeout => @server.listen @port, @ip, 100

	requestHandler: (request, response) =>
		console.log "#{request.method}: #{request.url}"
		try
			path = @root + request.url
			if fs.isDir path
				path += if request.url[request.url.length-1] is '/' then '' else '/'
				if fs.existsSync path + 'index.html'
					response.writeHead 200, 'Content-Type': 'text/html'
					response.end fs.readFileSync path + 'index.html'
				else
					@listDir path, request.url, response
			else
				mimeType = @mimeMap[fs.getExtension path] ? @defaultMimeType
				response.writeHead 200, 'Content-Type': mimeType
				response.end fs.readFileSync path
		catch error
			console.log "ERROR 404: #{request.url} #{error}"
			response.end 'ERROR 404'

	listDir: (path, url, response) =>
		files = fs.readdirSync path
		response.writeHead 200, 'Content-Type': 'text/html'
		response.write '<!DOCTYPE html><html><head></head><body>'
		if url isnt '/'
			response.write '<a href="..">[..]</a><br/>'
		for file in files
			fileName = if fs.isDir "#{path}/#{file}" then "[#{file}]" else file
			response.write "<a href=\"#{url}/#{file}/\">#{fileName}</a><br/>"
		response.end '</body></html>'
