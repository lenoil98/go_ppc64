rm -rf ../../go-freebsd-ppc64le-bootstrap
env GOOS=freebsd GOARCH=ppc64le GOROOT_BOOTSTRAP=/usr/local/go120 sh bootstrap.bash
