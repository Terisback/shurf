module pevo

fn test_pevo() {
	assert true
}

// import net
// import pevo

// fn main() {
// 	mut listener := net.listen_tcp(.ip6, ':8080') ?
// 	listener.sock.set_option_bool(.reuse_addr, true) ?

// 	mut p := pevo.new(1024) ?
// 	mut loop := p.create_loop(60) ?
// 	p.add(mut loop, listener.sock, pevo.read, 0, access_callback, voidptr(0)) ?
// 	for {
// 		print('.')
// 	}
// }

// fn setup_sock(fd int) {
// 	on := 1
// 	r := C.setsockopt(fd, C.IPPROTO_TCP, C.TCP_NODELAY, &on, sizeof(on))
// 	assert r == 0
// 	r = C.fcntl(fd, C.F_SETFL, C.O_NONBLOCK)
// 	assert r == 0
// }

// fn close_conn(mut p pevo.Pevo, mut loop pevo.Loop, fd int) {
// 	p.delete(mut loop, fd)
// 	C.close(fd)
// 	println('closed $fd')
// }

// fn access_callback(mut p pevo.Pevo, mut loop pevo.Loop, fd int, events pevo.Event, cb_arg voidptr) {
// 	new_fd := C.accept(fd, voidptr(0), voidptr(0))
// 	if new_fd != -1 {
// 		println('connected $new_fd')
// 		p.add(mut loop, new_fd, pevo.read, pevo.timeout_secs, rw_callback, cb_arg)
// 	}
// }

// fn rw_callback(mut p pevo.Pevo, mut loop pevo.Loop, fd int, events pevo.Event, cb_arg voidptr) {
// 	if (events & pevo.timeout) != 0 {
// 		close_conn(mut p, mut loop, fd)
// 	} else if (events & pevo.read) != 0 {
// 		buf := [1024]char{}
// 		r := C.read(fd, buf, sizeof(buf))
// 		match r {
// 			0 {
// 				// connection closed by peer
// 				close_conn(mut p, mut loop, fd)
// 			}
// 			-1 {
// 				// try again later
// 				if C.errno != C.EAGAIN && C.errno != C.EWOULDBLOCK {
// 					// fatal error
// 					close_conn(mut p, mut loop, fd)
// 				}
// 			}
// 			else {
// 				// send data
// 				if C.write(fd, buf, r) != r {
// 					// failed to send all data at once, close
// 					close_conn(mut p, mut loop, fd)
// 				}
// 			}
// 		}
// 	}
// }
