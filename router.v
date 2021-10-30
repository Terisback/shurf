module shurf

import net.http

pub struct Wildcard {}

pub type Param = string

pub type RouteSegment = Param | Wildcard | string

pub struct RouteParser {
pub:
	segments []RouteSegment
}

pub fn parse_route(pattern string) RouteParser {
	return RouteParser{}
}

pub fn (r RouteParser) matches(path string) bool {
	return false
}

pub struct Route {
	root   bool
	parser RouteParser
pub:
	method   http.Method
	path     string
	params   []string
	handlers []Handler
}

pub struct Router {
	routes map[string]Route
}
