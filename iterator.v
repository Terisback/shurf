module shurf

fn iterator<T>(array []T) &Iterator<T> {
	return &Iterator<T>{
		array: array
	}
}

[heap; noinit]
struct Iterator<T> {
	array []T
mut:
	idx      usize
	peek_idx usize = 1
}

fn (mut i Iterator<T>) next() ?T {
	defer {
		i.idx += 1
		i.peek_idx = i.idx + 1
	}
	return i.get(i.idx)
}

fn (mut i Iterator<T>) peek() ?T {
	defer {
		i.peek_idx++
	}
	return i.get(i.peek_idx)
}

fn (mut i Iterator<T>) skip(n usize) {
	i.idx += n
	i.peek_idx = i.idx + 1
}

fn (mut i Iterator<T>) take_while(predicate fn (T) bool) []T {
	mut taked_arr := []T{}

	if i.in_bounds(i.idx) {
		for elem in i.array[i.idx..] {
			if predicate(elem) {
				taked_arr << elem
			} else {
				break
			}
		}
	}

	return taked_arr
}

[direct_array_access]
fn (i Iterator<T>) get(index usize) ?T {
	if i.in_bounds(index) {
		return i.array[index]
	}
	return error('out of bounds')
}

fn (i Iterator<T>) in_bounds(index usize) bool {
	return 0 <= index && index < i.array.len
}