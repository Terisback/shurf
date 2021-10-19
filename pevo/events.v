module pevo

pub type Event = u32

pub const (
	read      = Event(1)
	write     = Event(2)
	readwrite = Event(3)
	timeout   = Event(4)
	add       = Event(0x4000_0000)
	del       = Event(0x2000_0000)
)

[inline]
fn event_matches(e u32, mask u32) bool {
	return e & mask == mask
}

[inline]
pub fn (e Event) matches(mask Event) bool {
	return event_matches(e, mask)
}
