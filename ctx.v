module shurf

import net
import net.http
import os
import io

pub const (
	// When doing `ctx.send_file()` it checks that file meets this size requirement.
	// We need that because currently we does not handling file streams, so before sending file to client we should got it in memory.
	max_send_file_size = 2 * 1024 * 1024
)

pub struct Context<U> {
mut:
	// workaround till we have req, res streams so we just close them
	done bool
	// userdata
	userdata U
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
pub fn (mut ctx Context<U>) status(code http.Status) {
	ctx.res.set_status(code)
}

// Sets the response content type to `mime_type`.
pub fn (mut ctx Context<U>) content_type(mime_type string) {
	ctx.res.header.set(.content_type, mime_type)
}

// Returns request body.
pub fn (ctx Context<U>) body() string {
	return ctx.req.data
}

// Sets response body to `payload`.
pub fn (mut ctx Context<U>) payload(payload string) {
	ctx.res.text = payload
}

// Sends html `payload` with status `code`.
pub fn (mut ctx Context<U>) html(code http.Status, payload string) ? {
	ctx.content_type('text/html')
	ctx.payload(payload)
	ctx.send_response() ?
}

// Sends text `payload` with status `code`.
pub fn (mut ctx Context<U>) text(code http.Status, payload string) ? {
	ctx.content_type('text/plain')
	ctx.payload(payload)
	ctx.send_response() ?
}

// Sends json `payload` with status `code`.
pub fn (mut ctx Context<U>) json(code http.Status, payload string) ? {
	ctx.content_type('application/json')
	ctx.payload(payload)
	ctx.send_response() ?
}

// Redirect client to `url`.
// Sets status to 302 (.found) and adds `location` to header.
pub fn (mut ctx Context<U>) redirect(url string) ? {
	ctx.status(.found)
	ctx.res.header.add(.location, url)
	ctx.send_response() ?
}

// Returns the ip address from the current client.
pub fn (ctx Context<U>) ip() string {
	mut ip := ctx.req.header.get(.x_forwarded_for) or { '' }

	if ip == '' {
		ip = ctx.req.header.get_custom('X-Real-Ip') or { '' }
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
pub fn (ctx Context<U>) cookies(key string) ?string {
	return ctx.req.cookies[key] or { return error('cookie not found') }
}

// Sets response cookie.
pub fn (mut ctx Context<U>) cookie(cookie http.Cookie) {
	ctx.res.header.add(.set_cookie, cookie.str())
}

pub fn (mut ctx Context<U>) send_file(file string) ? {
	path := os.real_path(file)

	if !os.is_file(path) && os.is_dir(path) {
		return error('send_file(`$path`): you can not send directories, archive it nor send files separately')
	}

	if !os.is_readable(path) {
		return error('send_file(`$path`): unable to read file')
	}

	if os.file_size(path) >= shurf.max_send_file_size {
		return error("send_file(`$path`): file size is limited to 2MB because lack of streams, PR's are welcome")
	}

	f := os.open(file) or { return error('send_file(`$path`): unable to open file, $err') }

	b := io.read_all(reader: f) ?
	ctx.res.text = b.bytestr()

	ctx.send_response() ?
}

// workaround till we have req, res streams so we just close them
fn (mut ctx Context<U>) mark_as_done() ? {
	if ctx.done {
		return error('already done')
	}
	ctx.done = true
}

// workaround till we have req, res streams so we just close them
fn (mut ctx Context<U>) send_response() ? {
	ctx.mark_as_done() or { return error('unable to send, response already sended') }

	ctx.res.header.set(.content_length, ctx.res.text.len.str())
	ctx.conn.write(ctx.res.bytes()) or {
		return error('unable to send, connection it probably closed: $err')
	}
	return
}
