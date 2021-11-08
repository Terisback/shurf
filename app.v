module shurf

import sync
import net.http
import strconv

// App denotes the Shurf application.
// The `U` is userdata type that will be passed to Context.
[heap; noinit]
pub struct App<U> {
mut:
	mutex sync.Mutex
	// Route stack divided by HTTP methods
	stack [][]&Route
	// Route stack divided by HTTP methods and route prefixes
	tree_stack []map[string][]&Route
	// HTTP Server
	server http.Server
	// Context pool
	pool Pool
	// App config
	config Config
}

pub fn new<U>(config Config) &App<U> {
	return &App<U>{
		mutex: sync.new_mutex()
		stack: [][]&Route{len: 9}
		tree_stack: []map[string][]&Route{len: 9}
		server: http.Server{}
		pool: Pool{}
		config: config
	}
}

pub fn (mut app App<U>) get(prefix string, handlers ...Handler) {
	println('GET - "$prefix"')
	return
}

pub fn (mut app App<U>) listen(addr string) ? {
	app.server.port = strconv.atoi(addr) ?
	app.server.handler = app
	println("App name is '$app.config.app_name'")
	println('Starting at ${app.server.port}...')
	app.server.listen_and_serve() ?
}

fn (mut app App<U>) handle(req http.Request) http.Response {
	mut res := http.Response{
		header: http.new_header_from_map({
			http.CommonHeader.content_type: 'text/plain'
		})
	}
	mut status_code := 200
	res.text = match req.url {
		'/foo' {
			'bar\n'
		}
		'/hello' {
			'world\n'
		}
		'/' {
			'foo\nhello\n'
		}
		else {
			status_code = 404
			'Not found\n'
		}
	}
	res.status_code = status_code
	return res
}
