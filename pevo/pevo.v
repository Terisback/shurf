module pevo

[heap; noinit]
pub struct Pevo {
mut:
	fds []FileDescriptor

	max_fd    int
	num_loops int
}

pub fn new(int max_fd) &Pevo {
	return &Pevo{
		fds: []FileDescriptor{len: max_fd}
		max_fd: max_fd
	}
}

pub fn (mut p Pevo) set_timeout(mut loop Loop, fd int, secs int) {
	vi := fd / short_bits
	if p.fds[fd].timeout_idx != timeout_idx_unused {
		loop.timeout[p.fds[fd].timeout_idx].vec[vi] &= ~(u16(C.SHRT_MIN) >> (fd % short_bits))
		if loop.timeout[p.fds[fd].timeout_idx].vec[vi] == 0 {
			loop.timeout[p.fds[fd].timeout_idx].vec_of_vec[vi / short_bits] &= ~(u16(C.SHRT_MIN) >> (vi % short_bits))
		}
		p.fds[fd].timeout_idx = timeout_idx_unused
	}

	if secs != 0 {
		mut delta := (loop.now + secs - loop.timeout.base_time) / loop.timeout.resolution
		if delta >= timeout_vec_size {
			delta = timeout_vec_size - 1
		}
		p.fds[fd].timeout_idx = (loop.timeout.base_idx + delta) % timeout_vec_size
		loop.timeout[p.fds[fd].timeout_idx].vec[vi] |= u16(C.SHRT_MIN) >> (fd % short_bits)
		loop.timeout[p.fds[fd].timeout_idx].vec_of_vec[vi / short_bits] |= u16(C.SHRT_MIN) >> (vi % short_bits)
	}
}

pub fn (mut p Pevo) add(mut loop Loop, fd int, events Event, timeouts_in_secs int, callback Handler, userdata voidptr) ? {
	p.fds[fd] = FileDescriptor{
		loop_id: loop.loop_id
		timeout_idx: 255
		callback: callback
		userdata: userdata
	}

	p.update_events(mut loop, fd, events | add) or {
		p.fds[fd].loop_id = 0
		return err
	}

	p.set_timeout(mut loop, fd, timeouts_in_secs)

	return
}

pub fn (mut p Pevo) del(mut loop Loop, fd int) ? {
	loop.update_events(fd, del) ?
	p.set_timeout(mut loop, fd, 0)
	p.fds[fd].loop_id = 0
	return
}

pub fn (mut p Pevo) is_active(mut loop Loop, fd int) ? {
	return if loop != voidptr(0) {
		p.fds[fd].loop_id == loop.loop_id
	} else {
		p.fds[fd].loop_id != 0
	}
}

pub fn (mut p Pevo) get_events(mut loop Loop, fd int) ? {
	return p.fds[fd].events & readwrite
}

pub fn (mut p Pevo) set_events(mut loop Loop, fd int, events Event) ? {
	if p.fds[fd].events != events {
		loop.update_events(fd, events) ?
	}
}

pub fn (mut p Pevo) set_callback(mut loop Loop, fd int, callback Handler, userdata voidptr) {
	if !isnil(userdata) {
		p.fds[fd].userdata = userdata
	}
	p.fds[fd].callback = callback
}

pub fn (mut p Pevo) next_fd(mut loop Loop, current_fd int) ?int {
	// if current_fd != -1 {
	// 	// check for bounds
	// }
	for fd := current_fd + 1; fd < p.max_fd; fd++ {
		if loop.loop_id == p.fds[fd].loop_id {
			return fd
		}
	}

	return error('out of bounds')
}

pub fn (mut p Pevo) loop_once(mut loop Loop, max_wait int) ? {
	loop.now = C.time(0)
}

// [inline]
// fn rnd_up<T>(v T, d T) T {
// 	return (v + d - 1) / d * d
// }

// // aligned allocator with address scrambling to avoid cache line contention
// [unsafe]
// fn memalign(size usize, voidptr original_address, int clear) voidptr {
// 	unsafe {
// 		size += pevo.page_size + pevo.cache_line_size
// 		*original_address = malloc(new_size)

// 		if isnil(original_address) {
// 			return voidptr(0)
// 		}

// 		if clear != 0 {
// 			vmemset(*original_address, 0, new_size)
// 		}

// 		return rnd_up(u64(*original_address) + (C.rand() % pevo.page_size), pevo.cache_line_size)
// 	}
// }
