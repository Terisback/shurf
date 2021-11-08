module utils

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
