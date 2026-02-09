default:
	just --list

build-rpm:
    #!/usr/bin/env bash
    set -eou pipefail
    mkdir -p ./output
    
    CONTAINER_NAME="fedora43-builder"
    
    # Check if container exists
    if ! podman container exists "$CONTAINER_NAME"; then
        echo "Creating new container and installing dependencies..."
        podman run -d --name "$CONTAINER_NAME" -v "$PWD:/workspace:z" -w /workspace fedora:43 sleep infinity
        podman exec "$CONTAINER_NAME" bash -c "\
            dnf install -y rpm-build && \
            dnf builddep -y bazzite_updater.spec \
        "
    else
        # Start container if it's stopped
        if [ "$(podman inspect -f '{{{{.State.Status}}}}' "$CONTAINER_NAME")" != "running" ]; then
            echo "Starting existing container..."
            podman start "$CONTAINER_NAME"
        fi
    fi

    rm output/*.rpm
    
    VERSION=$(cat version.txt)
    git archive --format=tar.gz --prefix=bazzite_updater-$VERSION/ -o output/$VERSION.tar.gz HEAD
    
    # Clean and build fresh RPM
    echo "Building RPM..."
    podman exec "$CONTAINER_NAME" bash -c "\
        rm -rf ~/rpmbuild/BUILD ~/rpmbuild/BUILDROOT ~/rpmbuild/RPMS ~/rpmbuild/SRPMS && \
        mkdir -p ~/rpmbuild/SOURCES \
    "
    podman cp "output/$VERSION.tar.gz" "$CONTAINER_NAME:/root/rpmbuild/SOURCES/$VERSION.tar.gz"
    
    podman exec "$CONTAINER_NAME" bash -c "\
        rpmbuild -bb bazzite_updater.spec && \
        cp -v ~/rpmbuild/RPMS/*/*.rpm ./output/ \
    "
    rm output/$VERSION.tar.gz

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