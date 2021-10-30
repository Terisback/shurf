module shurf

import net
import net.http

pub struct Context<T> {
mut:
	// userdata
	app T
	// For internal use
	conn net.TcpConn
	// Map containing query params for the route.
	// Example: `http://localhost:3000/index?q=vpm&order_by=desc => { 'q': 'vpm', 'order_by': 'desc' }`
	query map[string]string
	// Multipart-from fields.
	form map[string]string
	// Files from multipart-form.
	files map[string][]http.FileData
	// Route
	route Route
pub:
	// HTTP Request
	req http.Request
pub mut:
	// HTTP Response, it will be sended after handler execution.
	// Feel free to change it yourself.
	res http.Response
}

// Sets the response status.
pub fn (mut ctx Context) status(code http.Status) {
	ctx.response.set_status(code)
}

// Sets the response content type to `mime_type`.
pub fn (mut ctx Context) content_type(mime_type string) {
	ctx.response.header.set(.content_type, mime_type)
}

// Returns request body.
pub fn (ctx Context) body() string {
	return ctx.request.data
}

// Sets response body to `payload`.
pub fn (mut ctx Context) payload(payload string) {
	ctx.response.text = payload
}

// Sends html `payload` with status `code`.
pub fn (mut ctx Context) html(code http.Status, payload string) ? {
	ctx.content_type('text/html')
	ctx.payload(payload)
	return ctx.send()
}

// Sends text `payload` with status `code`.
pub fn (mut ctx Context) text(code http.Status, payload string) ? {
	ctx.content_type('text/plain')
	ctx.payload(payload)
	return ctx.send()
}

// Sends json `payload` with status `code`.
pub fn (mut ctx Context) json(code http.Status, payload string) ? {
	ctx.content_type('application/json')
	ctx.payload(payload)
	return ctx.send()
}

// Redirect client to `url`.
// Sets status to 302 (.found) and adds `location` to header.
pub fn (mut ctx Context) redirect(url string) ? {
	ctx.set_status(.found)
	ctx.response.header.add(.location, url)
	return ctx.send()
}

// Returns the ip address from the current user.
pub fn (ctx Context) ip() string {
	mut ip := ctx.request.header.get(.x_forwarded_for) or { '' }

	if ip == '' {
		ip = ctx.request.header.get_custom('X-Real-Ip') or { '' }
	}

	if ip.contains(',') {
		ip = ip.all_before(',')
	}

	if ip == '' {
		ip = ctx.conn.peer_ip() or { '' }
	}
	return ip
}

// Gets a cookie from request by a key.
pub fn (ctx &Context) cookies(key string) ?string {
	return ctx.request.cookies[key] or { return error('cookie not found') }
}

// Sets response cookie.
pub fn (mut ctx Context) cookie(cookie http.Cookie) {
	ctx.response.header.add(.set_cookie, cookie.str())
}

// fn (mut ctx Context) send_response() bool {
// 	ctx.mark_as_done() or { return false }

// 	ctx.response.header.set(.content_length, ctx.response.text.len.str())
// 	ctx.conn.write(ctx.response.bytes()) or { return false }
// 	return true
// }