module pevo

#include <errno.h>
// Docs used <https://man7.org/linux/man-pages/man7/epoll.7.html>
#include <sys/epoll.h>
#include <unistd.h>

const (
	epollin  = C.EPOLLIN
	epollout = C.EPOLLOUT
	epollerr = C.EPOLLERR
	epollhup = C.EPOLLHUP
)

const (
	epoll_ctl_add = C.EPOLL_CTL_ADD
	epoll_ctl_mod = C.EPOLL_CTL_MOD
	epoll_ctl_del = C.EPOLL_CTL_DEL
)

struct C.epoll_event {
mut:
	events u32
	data   C.epoll_data
}

struct C.epoll_data {
mut:
	ptr voidptr
	fd  int
	u32 u32
	u64 u64
}

// returns a file descriptor referring to the new epoll instance.
fn C.epoll_create(size int) int

// This system call is used to add, modify, or remove entries in the
// interest list of the epoll(7) instance referred to by the file
// descriptor epfd.  It requests that the operation op be performed
// for the target file descriptor, fd.
fn C.epoll_ctl(epfd int, op int, fd int, event &C.epoll_event) int

fn C.epoll_wait(epfd int, events voidptr, max_events int, timeout int) int

[heap; noinit]
pub struct Loop {
	loop_id u16
mut:
	events   [1024]C.epoll_event
	timeout  Timeout
	now      C.time_t
	epoll_fd int
}

pub fn (mut p Pevo) create_loop(max_timeout int) ?&Loop {
	epoll_fd := C.epoll_create(p.max_fd)
	if epoll_fd == -1 {
		return error('epoll_create failed')
	}

	p.num_loops += 1
	loop := &Loop{
		loop_id: p.num_loops
		epoll_fd: epoll_fd
	}

	return loop
}

pub fn (mut p Pevo) update_events(mut loop Loop, fd int, events Event) ? {
	target := p.fds[fd]

	if ((events & readwrite) == target.events) {
		return
	}

	mut ev := C.epoll_event{}
	ev.events = if events.matches(read) { pevo.epollin } else { 0 }
	ev.events |= if events.matches(write) { pevo.epollout } else { 0 }
	ev.data.fd = fd

	if (events & readwrite) == 0 {
		epoll_ret := C.epoll_ctl(loop.epoll_fd, pevo.epoll_ctl_del, fd, &ev)
	} else {
		epoll_ret := C.epoll_ctl(loop.epoll_fd, if target.events == 0 {
			pevo.epoll_ctl_add
		} else {
			pevo.epoll_ctl_mod
		}, fd, &ev)
	}

	target.events = events

	return
}

fn (mut p Pevo) poll_once(mut loop Loop, max_wait int) ? {
	nevents := C.epoll_wait(loop.epoll_fd, loop.events, loop.events.len, max_wait * 1000)
	if nevents == -1 {
		return error('epoll_wait failed')
	}

	for i in 0 .. nevents {
		event := loop.events[i]
		target := p.fds[event.data.fd]

		if loop.loop_id == target.loop_id && (target.events & readwrite) != 0 {
			mut revents := if event_matches(event.events, pevo.epollin) { read } else { 0 }
			revents |= if event_matches(event.events, pevo.epollout) { write } else { 0 }
			if revents != 0 {
				target.callback(&loop, event.data.fd, revents, target.cb_arg)
			} else {
				event.events = 0
				C.epoll_ctl(loop.epoll_fd, pevo.epoll_ctl_del, event.data.fd, event)
			}
		}
	}

	return
}
