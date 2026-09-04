default:
    just --list

# generate new translations template
potfile:
    cmake --build build --target potfile

# devcontainer
build:
    cmake -B build -S . -D_INCLUDE_SUBMODULES=OFF -DCMAKE_INSTALL_PREFIX=$PWD/build/install-root -D_USE_XDG_CONFIG=ON
    cmake --build build --target install

# devcontainer
install-controllable:
    cd /workspaces/bazzite-updater/src/components/controllable
    just build
    sudo cmake --install build
    cd /workspaces/bazzite-updater

# devcontainer
brun:
    #!/usr/bin/env bash
    just build
    just run

run:
    #!/usr/bin/env bash
    source ./build/prefix.sh
    bazzite-updater

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

# devcontainer, copy src/resources to proper location
symlink-configs:
    #!/usr/bin/env bash
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
