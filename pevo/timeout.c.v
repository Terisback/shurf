module pevo

const (
	short_bits         = sizeof(u16) * 8
	timeout_idx_unused = C.UCHAR_MAX
	// todo: move to config
	timeout_vec_size   = 128
)

struct Timeout {
mut:
	vec        []i16
	vec_of_vec []i16
	base_idx   usize
	base_time  C.time_t
	resolution int
}
