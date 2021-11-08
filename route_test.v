module shurf

fn test_router() {
	parser := RouteParser{
		segments: [RouteSegment('/user/'), DynamicSegment{name: 'name', optional: false}]
	}

	mut path := '/user/a/some'
	mut params := map[string]string{}
	mut matched := false

	path, params, matched = parser.matches(path, params)
	dump(path)
	dump(params)
	dump(matched)

	if !matched {
		//continue
		return
	}

	// ...
	println('cool')
	// break
}