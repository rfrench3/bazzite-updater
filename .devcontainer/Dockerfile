FROM archlinux:latest

# Update system and install required packages
RUN pacman -Syu --noconfirm \
    astyle \
    cmake \
    git \
    extra-cmake-modules \
    curl \
    sudo \
    # Basic build tools - gnu
    autoconf \
    automake \
    bison \
    flex \
    gcc \
    gperf \
    make \
    texinfo \
    # Basic build tools - llvm
    clang \
    # Basic build tools - build systems
    meson \
    ninja \
    # Basic build tools - rust
    corrosion \
    # Basic build tools - others
    boost \
    docbook-xsl \
    doxygen \
    gi-docgen \
    intltool \
    pkg-config \
    # Qt-related
    libaccounts-qt \
    packagekit \
    phonon-qt6 \
    poppler-qt6 \
    qca-qt6 \
    qcoro-qt6 \
    qt6 \
    qtkeychain-qt6 \
    # Others/Unsorted
    black-hole-solver \
    check \
    eigen \
    enchant \
    exiv2 \
    flatpak \
    fluidsynth \
    freecell-solver \
    giflib \
    glib2-devel \
    gtk3 \
    itstool \
    jasper \
    kdsoap \
    libcanberra \
    libdisplay-info \
    libdmtx \
    libei \
    libfakekey \
    libgit2 \
    libical \
    libolm \
    libpwquality \
    libqalculate \
    libraw \
    libutempter \
    libxcvt \
    libxmlb \
    libxss \
    lmdb \
    microsoft-gsl \
    mlt \
    mpv \
    networkmanager \
    openal \
    openexr \
    plymouth \
    power-profiles-daemon \
    python-build \
    python-cairo \
    python-pip \
    python-setuptools \
    python-sphinx \
    qgpgme-qt6 \
    qrencode \
    ruby-sass \
    ruby-test-unit \
    sane \
    sccache \
    shared-mime-info \
    signond \
    udisks2 \
    upower \
    vala \
    vlc \
    vulkan-headers \
    wayland-protocols \
    xapian-core \
    xerces-c \
    xf86-input-libinput \
    xf86-input-wacom \
    xmlto \
    xorg-server-devel \
    xsd \
    zxing-cpp \
    # kcoreaddons
    pyside6 \
    shiboken6 \
    # plasma-desktop
    xdotool \
    # appstream
    gobject-introspection \
    xf86-input-evdev \
    # okular
    discount \
    djvulibre \
    ebook-tools \
    libspectre \
    libzip \
    # drkonqi
    python-psutil \
    python-pygdbmi \
    python-sentry_sdk \
    # kpipewire
    pipewire-audio \
    # qtwebengine
    python-html5lib \
    # karchive
    lzip \
    # cxx-rust-cssparser
    rust \
    # kf6
    kirigami \
    kcoreaddons \
    kconfig \
    ki18n \
    kiconthemes \
    kirigami-addons \
    qqc2-desktop-style \
    # Let the app have breeze theme in the container
    plasma-integration
    

RUN mkdir -p /run/host/usr/share/ublue-os/

# Create vscode user with sudo access
RUN groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid 1000 -m -s /bin/bash vscode \
    && echo 'vscode ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

# Give vscode access to the input group (for testing controllers)
RUN groupadd -f input \
    && usermod -a -G input vscode

## Let breeze work while testing (not necessary)
ENV XDG_CURRENT_DESKTOP=KDE
