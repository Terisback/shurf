module pevo

pub type Handler = fn (mut p Pevo, mut loop Loop, fd int, events Event, userdata voidptr)
