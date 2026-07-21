default:
    just --list

# devcontainer
build:
    cmake -B build -D_INCLUDE_SUBMODULES=ON -DTESTING_BUILD=ON
    cmake --build build

# devcontainer
run:
    just build
    ./build/bin/bazzite-updater

# devcontainer
test:
    just build
    ctest --test-dir build --output-on-failure

# devcontainer
update-submodules:
    git submodule update --init --recursive --remote

# host
build-terra:
    #!/usr/bin/env bash
    podman run --rm --cap-add=SYS_ADMIN --privileged --volume ./packaging/terra:/anda --volume mock_cache:/var/cache/mock --workdir /anda ghcr.io/terrapkg/builder:frawhide anda build -c terra-rawhide-x86_64 bazzite-updater/pkg
    just terra-post

# host
build-terra-44:
    #!/usr/bin/env bash
    podman run --rm --cap-add=SYS_ADMIN --privileged --volume ./packaging/terra:/anda --volume mock_cache:/var/cache/mock --workdir /anda ghcr.io/terrapkg/builder:f44 anda build -c terra-44-x86_64 bazzite-updater/pkg
    just terra-post

# host
build-flatpak: output
    #!/usr/bin/env bash
    set -eou pipefail
    flatpak-builder --force-clean --repo=output/repo builddir .flatpak-manifest.json
    flatpak build-bundle output/repo output/bazzite-updater.flatpak io.github.rfrench3.bazzite-updater
    rm -r output/repo
    rm -r builddir

# devcontainer, copy src/resources to proper location
symlink-configs:
    #!/usr/bin/env bash
    set -eou pipefail
    sudo rm -r /etc/bazzite-updater
    sudo ln -s /workspaces/bazzite-updater/src/resources /etc/bazzite-updater

[private]
output:
    mkdir -p output

[private]
clear-output:
    rm output/*

[private]
terra-post:
    #!/usr/bin/env bash
    mv ./packaging/terra/anda-build/rpm/rpms/* ./output
    rm -r ./packaging/terra/anda-build
