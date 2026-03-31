default:
	just --list

#devcontainer
build: 
    cmake -B build
    cmake --build build

#devcontainer
run:
    just build
    ./build/bin/bazzite_updater

#devcontainer
test:
    just build
    ctest --test-dir build --output-on-failure


#host
build-rpm:
    #!/usr/bin/env bash
    set -eou pipefail
    mkdir -p ./output
    rm -f ./output/*.rpm

    podman run --rm -v "$PWD:/workspace:z" -w /workspace fedora:43 bash -lc '
        set -eou pipefail
        dnf install -y rpm-build
        dnf builddep -y bazzite_updater.spec

        export HOME=/root
        VERSION=$(cat version.txt)
        mkdir -p ~/rpmbuild/SOURCES
        tar --transform "s|^\\.|bazzite_updater-$VERSION|" -czf ~/rpmbuild/SOURCES/$VERSION.tar.gz .
        rpmbuild -bb bazzite_updater.spec
        cp -v ~/rpmbuild/RPMS/*/*.rpm /workspace/output/
    '

#host
build-flatpak: output
	#!/usr/bin/env bash
	set -eou pipefail
	flatpak-builder --force-clean --repo=output/repo builddir .flatpak-manifest.json
	flatpak build-bundle output/repo output/bazzite_updater.flatpak io.github.rfrench3.bazzite_updater
	rm -r output/repo
	rm -r builddir

[private]
output:
	mkdir -p output