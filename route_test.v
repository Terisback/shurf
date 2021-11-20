module shurf

fn test_router_parsing() ? {
	dump(parse_route('/some/:body/haha') ?)
	dump(parse_route('/some/:body?/haha') ?)
	dump(parse_route('/some/:b-:ody./haha') ?)
	dump(parse_route('/some/*some/haha') ?)
	dump(parse_route('some/*some/haha') ?)
	parse_route('/**') or { assert err is ErrDoubleDynamicSegment }
	parse_route('/*+') or { assert err is ErrDoubleDynamicSegment }
	parse_route('/+*') or { assert err is ErrDoubleDynamicSegment }
	parse_route('/++') or { assert err is ErrDoubleDynamicSegment }
}

fn test_router_matching() {
	parser := RouteParser{
		segments: [RouteSegment('/user/'), DynamicSegment{
			name: 'name'
			optional: false
		}]
	}

	mut path := '/user/a/some'
	mut params := map[string]string{}
	mut matched := false

	path, params, matched = parser.matches(path, params)
	dump(path)
	dump(params)
	dump(matched)
	if !matched {
		// continue
		return
	}

	// ...
	println('cool')
	// break
}
