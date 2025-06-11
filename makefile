build:
	@ drifblim src/lavish.tal roms/lavish.rom
	@ drifblim src/thrift.tal roms/thrift.rom

run: build
	@bash -c '\
		set -e; \
		logfile=$$(mktemp); \
		socat -d -d pty,raw,echo=0 pty,raw,echo=0 2> $$logfile & \
		socat_pid=$$!; \
		sleep 0.1; \
		pty1=$$(grep -oP "PTY is (/dev/pts/[0-9]+)" $$logfile | sed -n 1p | awk "{print \$$3}"); \
		pty2=$$(grep -oP "PTY is (/dev/pts/[0-9]+)" $$logfile | sed -n 2p | awk "{print \$$3}"); \
		uxncli roms/lavish.rom < $$pty1 > $$pty1 & \
		pidA=$$!; \
		uxncli roms/thrift.rom < $$pty2 > $$pty2 & \
		pidB=$$!; \
		trap "kill $$socat_pid $$pidA $$pidB 2>/dev/null" EXIT; \
		wait $$pidA $$pidB; \
	'

clean:
	@ rm -rf roms

install: build
	@ cp roms/* ~/roms
