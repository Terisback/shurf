module shurf

pub const (
	method_get     = 'GET' // RFC 7231, 4.3.1
	method_head    = 'HEAD' // RFC 7231, 4.3.2
	method_post    = 'POST' // RFC 7231, 4.3.3
	method_put     = 'PUT' // RFC 7231, 4.3.4
	method_patch   = 'PATCH' // RFC 5789
	method_delete  = 'DELETE' // RFC 7231, 4.3.5
	method_connect = 'CONNECT' // RFC 7231, 4.3.6
	method_options = 'OPTIONS' // RFC 7231, 4.3.7
	method_trace   = 'TRACE' // RFC 7231, 4.3.8
	method_use     = 'USE'
)

const methods_count = 9

pub type Handler = fn (mut ctx Context) ?
