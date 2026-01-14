
<h1>Bazzite Updater</h1>

<h2 align="center">A Graphical Frontend for the updating and rebasing tools used by Universal Blue.</h2>

![Updating Screen](screenshots/controller_main.webp)

<h1 align="center">Features</h1>

<p>This is a convenient, easy-to-use interface for updating your Universal Blue system.</p>

- Simple by default, with advanced features still present
- Full touchscreen support through Kirigami
- Full controller support through SDL3

<br>

<h1 align="center">Icons</h1>

<p>The custom icons used by this app come from Bazzite.</p>

- https://github.com/ublue-os/bazzite/blob/main/system_files/desktop/shared/usr/share/ublue-os/bazzite/update.svg
- https://github.com/ublue-os/bazzite/blob/main/system_files/desktop/shared/usr/share/ublue-os/bazzite/logo.svg

<br>

<h1 align="center">Requirements</h1>

This GUI is only useful if you have `uupd` installed. If you are using a Universal Blue based system, you almost certainly do!

- https://github.com/ublue-os/uupd

<br>

<h1 align="center">Where to Install the Latest Release</h1>

I will publish flatpaks to the GitHub releases to distribute it until I am further in development.

**NOTE: This is not a sandboxed flatpak.** 
Flatpaks are usually heavily sandboxed, but this one is not for the following reasons:
--talk-name=org.freedesktop.Flatpak (run arbitrary commands on host system, used for systemctl and journalctl)
--device=input                      (read all input devices, used for SDL3 controller support)

- https://github.com/rfrench3/bazzite_updater/releases

<br>

<h1 align="center">License</h1>

<p>GPL-2.0-or-later. See LICENSES for details.</p>

<br>

<h1 align="center">Developer Instructions</h1>

I develop this project in a devcontainer with vscode and test it on bazzite by installing it as a flatpak through github artifacts, or locally with the following command:
```bash
flatpak-builder --install --user --force-clean app .flatpak-manifest.json
```

Before I set up the devcontainer, I developed this project primarily in an Arch Linux distrobox. These are the instructions I used to recreate it:
```
// in distroshelf, use dockers arch latest with init system and custom home directory

IN THE BASHRC:
    export XDG_CURRENT_DESKTOP=KDE
    export PATH="$HOME/.local/bin:$PATH"

sudo pacman -Sy --noconfirm plasma-integration kdevelop kapptemplate astyle cmake git extra-cmake-modules systemd

plasma-apply-desktoptheme breeze-dark

sudo rm /usr/bin/flatpak

cd ~
curl 'https://invent.kde.org/sdk/kde-builder/-/raw/master/scripts/initial_setup.sh?ref_type=heads' > initial_setup.sh
bash initial_setup.sh

kde-builder --generate-config

kde-builder --install-distro-packages # Requires a user input
```
