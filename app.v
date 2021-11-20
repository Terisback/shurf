module shurf

import sync
import net.http
import strconv

pub struct Config {
pub mut:
	app_name string
}

// App denotes the Shurf application.
[heap; noinit]
pub struct App {
mut:
	mutex sync.Mutex
	// Userdata
	userdata voidptr
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

pub fn new(userdata voidptr, config Config) &App {
	return &App{
		mutex: sync.new_mutex()
		userdata: userdata
		stack: [][]&Route{len: methods_count}
		tree_stack: []map[string][]&Route{len: methods_count}
		server: http.Server{}
		pool: Pool{}
		config: config
	}
}

pub fn (mut app App) get(prefix string, handlers ...Handler) {
	println('GET - "$prefix"')
	return
}

pub fn (mut app App) listen(addr string) ? {
	app.server.port = strconv.atoi(addr) ?
	app.server.handler = app
	app.server.listen_and_serve() ?
}

fn (mut app App) handle(req http.Request) http.Response {
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
