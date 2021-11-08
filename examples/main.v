module main

import shurf

struct App {}

fn some(ctx shurf.Context<App>) ? {
	println("hi!")
	return
}

fn main() {
	mut app := shurf.new<App>(app_name: 'example')
	app.get('/ass', some)
	app.listen('8080') ?
}
