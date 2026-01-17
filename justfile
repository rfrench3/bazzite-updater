default:
	just --list

install-flatpak:
	flatpak-builder --install --user --force-clean app .flatpak-manifest.json

run-flatpak: 
	flatpak run io.github.rfrench3.bazzite_updater

install-run-flatpak:
	just install-flatpak && just run-flatpak
