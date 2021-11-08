module shurf

import net.http
import utils

enum DynamicSegmentType {
	named
	plus
	wildcard
}

// Dynamic route segment, it can be either a normal parameter or a wildcard.
struct DynamicSegment {
pub:
	name     string
	optional bool
}

type RouteSegment = DynamicSegment | string

struct RouteParser {
	segments []RouteSegment
}

fn parse_route(pattern string) RouteParser {
	return RouteParser{}
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
						return '', merge_maps(params, route_params), true
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

	return path[path_idx..], merge_maps(params, route_params), true
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
