process.nextTick ->
	server = new HttpServer 'client', '127.0.0.1', 80
	server.start()
