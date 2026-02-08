set shell := ["bash", "-uc"]
export UBLUE_ROOT := env("UBLUE_ROOT", "/app/output")
export TARGET := "bazzite_updater"
export SOURCE_DIR := UBLUE_ROOT + "/" + TARGET
export RPMBUILD := UBLUE_ROOT + "/rpmbuild"

default:
	just --list

# run in devcontainer
build:
	cmake -B build
	cmake --build build

# run in devcontainer
run: build
	./build/bin/bazzite_updater

# run on host
build-rpm:
	#!/usr/bin/env bash
	set -eou pipefail
	if ! podman image exists rpm-builder; then \
		podman build -t rpm-builder -f Containerfile.builder; \
	fi
	podman create --replace --name rpm-export localhost/rpm-builder
	podman cp rpm-export:/rpms ./output
	podman rm rpm-export

# run on host
remake-container:
	podman rmi rpm-builder

# run on host
build-flatpak: output
	#!/usr/bin/env bash
	set -eou pipefail
	flatpak-builder --force-clean --repo=output/repo builddir .flatpak-manifest.json
	flatpak build-bundle output/repo output/bazzite_updater.flatpak io.github.rfrench3.bazzite_updater
	rm -r output/repo

# run on host
install-flatpak:
	flatpak-builder --install --user --force-clean app .flatpak-manifest.json

# run on host
run-flatpak: 
	flatpak run io.github.rfrench3.bazzite_updater

# run on host
install-run-flatpak:
	just install-flatpak && just run-flatpak


[private]
spec: output
	rpkg spec --outdir "$PWD/output"

[private]
create-source-tarball: output
	git archive --format=tar.gz --prefix=bazzite_updater-0.4.0/ -o output/0.4.0.tar.gz HEAD

[private]
build-rpm-p:
	rpkg local --outdir "$PWD/output"

[private]
builddep:
	dnf builddep -y output/bazzite_updater.spec

# Used internally by build containers
container-install-deps:
	#!/usr/bin/env bash
	set -eou pipefail
	dnf install                       \
		--disablerepo='*'             \
		--enablerepo='fedora,updates' \
		--setopt install_weak_deps=0  \
		--nodocs                      \
		--assumeyes                   \
		'dnf-command(builddep)'       \
		rpkg                          \
		rpm-build                     \
		git

container-rpm-build: container-install-deps spec create-source-tarball builddep build-rpm-p
	#!/usr/bin/env bash
	set -eou pipefail

	# clean up files
	for RPM in ${UBLUE_ROOT}/*/*.rpm; do
		NAME="$(rpm -q $RPM --queryformat='%{NAME}')"
		mkdir -p "${UBLUE_ROOT}/ublue-os/rpms/"
		cp "${RPM}" "${UBLUE_ROOT}/ublue-os/rpms/$(rpm -q "${RPM}" --queryformat='%{NAME}.rpm')"
	done

output:
	mkdir -p output

clean:
	rm -rf "$UBLUE_ROOT"


