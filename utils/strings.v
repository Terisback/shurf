module utils

// Comparison of the `left` string to the `right` with the `at` offset.
// Does bounds checking of `at`, so it fails for you with ErrOutOfBounds.
pub fn compare_at(left string, right string, at usize) ?bool {
	// checking for bounds
	if usize(left.len) < at + usize(right.len) {
		return IError(ErrOutOfBounds{})
	}

	// It's a little bit faster than
	// `left[int(at)..int(at) + right.len] == right`
	// and works fine with autofree
	unsafe {
		return C.memcmp(left.str + at, right.str, usize(right.len)) == 0
	}
}

// Constant time string comparison.
// First argument should be user input,
// second argument is internal, known string that’s being checked for a match
[direct_array_access]
pub fn secure_compare(internal string, outside string) bool {
	mut m := int(0)
	mut i := usize(0)
	mut j := usize(0)
	mut k := usize(0)

	for {
		m |= outside[i] ^ internal[j]

		if outside[i] == `\0` {
			break
		}

		i++

		if internal[j] != `\0` {
			j++
		}

		if internal[j] == `\0` {
			k++
		}
	}

	return m == 0
}

// Works like string.split() but with splitset
pub fn split_any(source string, splitset ...byte) []string {
	// Do not provide zero length splitset, please :(
	if splitset.len == 0 {
		return source.split_nth('', 0)
	}

	mut prev_idx := 0
	mut result := []string{}

	for i, _ in source {
		if source[i] in splitset {
			result << source[prev_idx..i]
			prev_idx = i + 1
		}
	}

	result << source[prev_idx..]

	return result
}
