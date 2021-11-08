module shurf

fn merge_maps(left map[string]string, right map[string]string) map[string]string {
	mut result := left.clone()
	for k, v in right {
		result[k] = v
	}
	return result
} 