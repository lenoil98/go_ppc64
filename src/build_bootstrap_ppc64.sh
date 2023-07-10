rm -rf ../../go-freebsd-ppc64-bootstrap
env GOOS=freebsd GOARCH=ppc64 GOROOT_BOOTSTRAP=/usr/local/go120 sh bootstrap.bash
