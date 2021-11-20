module shurf

import net.http
import utils

[noinit]
pub struct ErrDoubleDynamicSegment {
pub:
	msg  string = 'two dynamic segments in row'
	code int
}

pub struct Route {
	parser RouteParser
pub:
	method http.Method
	// Raw route path
	path string
	// Param names of route
	params   []string
	handlers []Handler
}

// Dynamic route segment, it can be either a normal parameter or a wildcard.
struct DynamicSegment {
pub:
	name     string
	optional bool
}

type RouteSegment = DynamicSegment | string

struct RouteParser {
	plus_idx     int = 1
	wildcard_idx int = 1
	segments     []RouteSegment
}

[direct_array_access]
fn parse_route(pattern string) ?RouteParser {
	if pattern.len == 0 {
		return RouteParser{
			segments: [RouteSegment('/')]
		}
	}

	mut segment := []byte{}
	mut plus_idx := 1
	mut wildcard_idx := 1
	mut segments := []RouteSegment{}

	if pattern[0] != `/` {
		segment << `/`
	}

	for i := 0; i <= pattern.len; i++ {
		character := pattern[i]

		if character !in [`\\`, `:`, `*`, `+`] {
			segment << character
			continue
		} else if character == `\\` {
			if i < pattern.len - 1 && pattern[i + 1] in [`:`, `*`, `+`] {
				segment << pattern[i + 1]
				i++
			} else {
				segment << character
			}
			continue
		}

		if character == `:` && i == pattern.len - 1 {
			segment << character
		}

		if segment.len > 0 {
			segments << segment.bytestr()
			segment.clear()
		}

		match character {
			`:` {
				mut peek := i + 1
				mut optional := false
				for ; peek < pattern.len; peek++ {
					if pattern[peek] == `?` {
						optional = true
						break
					}

					if pattern[peek] in [`/`, `-`, `.`] {
						break
					}
				}

				segments << DynamicSegment{
					name: pattern[i + 1..peek]
					optional: optional
				}

				i = peek - 1
				if optional {
					i++
				}
			}
			`*` {
				if segments.len > 0 && segments.last() is DynamicSegment {
					return IError(ErrDoubleDynamicSegment{})
				}

				segments << DynamicSegment{
					name: '*' + wildcard_idx.str()
					optional: true
				}
				wildcard_idx++
			}
			`+` {
				if segments.len > 0 && segments.last() is DynamicSegment {
					return IError(ErrDoubleDynamicSegment{})
				}

				segments << DynamicSegment{
					name: '+' + plus_idx.str()
					optional: false
				}
				plus_idx++
			}
			else {
				panic('unreachable')
			}
		}
	}

	segments << segment.bytestr()

	return RouteParser{
		plus_idx: plus_idx
		wildcard_idx: wildcard_idx
		segments: segments
	}
}

// Parses the passed url and tries to match it against the route segments and determine params values.
// Returns (path string, params map[string]string, matched bool), if not matched, returns arguments as it is.
//
// Example:
// ```
// mut path := 'some/path'
// mut params := map[string]string{}
//
// for {
// 	path, params, matched := parser.matches(path, params)
//
// 	if !matched {
// 		continue
// 	}
//
// 	// ...
// }
// ```
//
fn (r RouteParser) matches(path string, params map[string]string) (string, map[string]string, bool) {
	// Static route with one segment
	if r.segments.len == 1 && r.segments[0] is string {
		if r.segments[0] as string == path {
			return '', params, true
		}

		return path, params, false
	}

	mut path_idx := 0
	mut route_params := map[string]string{}

	for i, segment in r.segments {
		match segment {
			// Static segment
			string {
				// Checking if static segment in bounds of path
				if path.len - path_idx < segment.len {
					return path, params, false
				}

				if matched := utils.compare_at(path, segment, usize(path_idx)) {
					if matched {
						path_idx += segment.len
						continue
					}
				}

				return path, params, false
			}
			DynamicSegment {
				// When it's the last segment of route
				if r.segments.len - 1 == i {
					if segment.optional || path.len - path_idx > 0 {
						route_params[segment.name] = path[path_idx..]
						return '', utils.merge_maps(params, route_params), true
					}

					return path, params, false
				}

				next_static := r.segments[i + 1]
				if next_static !is string {
					panic('unreachable, someone parsed the segments manually and did not think about that there can not be several dynamic parameters in a row')
				}

				static_idx := path.index_after(next_static as string, path_idx)
				// Not found next static route segment
				if static_idx == -1 {
					return path, params, false
				}

				if static_idx == path_idx && !segment.optional {
					return path, params, false
				}

				route_params[segment.name] = path[path_idx..static_idx]
				path_idx += static_idx - path_idx
			}
		}
	}

	return path[path_idx..], utils.merge_maps(params, route_params), true
}
