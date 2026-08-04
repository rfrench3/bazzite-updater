default:
    just --list

# generate new translations template
potfile:
    #!/bin/bash
    PROJECT_NAME="bazzite-updater"
    POT_FILE="po/${PROJECT_NAME}.pot"
    echo "Extracting messages for ${PROJECT_NAME}..."
    find src -type f \( -name "*.cpp" -o -name "*.h" -o -name "*.qml" \) > po/source_files.txt
    xgettext --from-code=UTF-8 -C -kde \
        --files-from=po/source_files.txt \
        -ci18n -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 \
        -ktr2i18n:1 -kI18N_NOOP:1 -kI18N_NOOP2:1c,2 \
        -kaliasLocale -kki18n:1 -kki18nc:1c,2 -kki18np:1,2 -kki18ncp:1c,2,3 \
        -o ${POT_FILE}
    rm po/source_files.txt
    echo "Done! Template generated at ${POT_FILE}"
    for po_file in po/*/${PROJECT_NAME}.po; do
        if [ -f "$po_file" ]; then
            echo "Updating $po_file..."
            msgmerge -U "$po_file" "${POT_FILE}"
        fi
    done
    echo "All translations updated!"

# devcontainer
build:
    cmake -B build -S . -D_INCLUDE_SUBMODULES=OFF -DCMAKE_INSTALL_PREFIX=$PWD/build/install-root
    cmake --build build --target install

# devcontainer
install-controllable:
    cd /workspaces/bazzite-updater/src/components/controllable
    just build
    sudo cmake --install build
    cd /workspaces/bazzite-updater

# devcontainer
run:
    just build
    XDG_DATA_DIRS=/workspaces/bazzite-updater/build/install-root/share ./build/install-root/bin/bazzite-updater

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
