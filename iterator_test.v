module shurf

fn test_string_array_iterator_next_and_peek() ? {
	some := 'shurf'.bytes()
	mut i := iterator(some)

	assert i.peek() ? == some[1]
	assert i.next() ? == some[0]
	assert i.peek() ? == some[2]
	assert i.peek() ? == some[3]
	assert i.next() ? == some[1]
	assert i.peek() ? == some[3]
}

fn teest_string_array_iterator_skip() ? {
	some := 'shurf'.bytes()
	mut i := iterator(some)

	i.skip(1)
	assert i.next() ? == some[1]
	i.skip(2)
	assert i.next() ? == some[3]
}

fn teest_string_array_iterator_take_while() ? {
	some := 'shurf'.bytes()
	mut i := iterator(some)
	i.skip(3)

	assert i.take_while(fn (s string) bool {
		return !s.starts_with('-')
	}) == some[4..7]
	assert i.peek() ? == some[7]
	assert i.next() ? == some[7]
}
