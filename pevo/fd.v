module pevo

pub struct FileDescriptor {
	loop_id     u16
	events      Event
	timeout_idx byte
	backend     int

	callback Handler
	userdata voidptr
}
