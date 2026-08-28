%global appid io.github.rfrench3.bazzite-updater

Name:           bazzite-updater
Version:        %(cat version.txt)
Release:        1%{?dist}
Summary:        Update your Bazzite system

License:        GPL-2.0-or-later
URL:            https://github.com/rfrench3/bazzite-updater
Source0:        %{url}/archive/refs/tags/%{version}.tar.gz

BuildRequires:  desktop-file-utils
BuildRequires:  libappstream-glib
BuildRequires:  systemd-rpm-macros

BuildRequires:  cmake
BuildRequires:  extra-cmake-modules
BuildRequires:  kf6-rpm-macros
BuildRequires:  cmake(SDL3)
BuildRequires:  cmake(Qt6Core)
BuildRequires:  cmake(Qt6DBus)
BuildRequires:  cmake(Qt6Gui)
BuildRequires:  cmake(Qt6Qml)
BuildRequires:  cmake(Qt6QuickControls2)
BuildRequires:  cmake(Qt6Svg)
BuildRequires:  cmake(Qt6Widgets)

BuildRequires:  cmake(KF6Kirigami)
BuildRequires:  cmake(KF6CoreAddons)
BuildRequires:  cmake(KF6Config)
BuildRequires:  cmake(KF6ColorScheme)
BuildRequires:  cmake(KF6I18n)
BuildRequires:  cmake(KF6IconThemes)
BuildRequires:  cmake(KF6KirigamiAddons)

Requires:       kf6-kirigami%{?_isa}
Requires:       kf6-kirigami-addons%{?_isa}
Requires:       kf6-qqc2-desktop-style%{?_isa}
Requires:       qqc2-breeze-style%{?_isa}
Requires:       qt6-controllable%{?_isa}

Provides:       bazzite-updater = %{version}-%{release}

%description
This is a convenient, easy-to-use interface for updating your Bazzite system.
- Simple and powerful
- Full support for all input types (keyboard/mouse, controller, touchscreen)

%prep
%autosetup

%build
%cmake
%cmake_build

%install
%cmake_install
%find_lang bazzite-updater

%check
appstream-util validate-relax --nonet %{buildroot}%{_kf6_metainfodir}/%{appid}.*.xml || :
desktop-file-validate %{buildroot}%{_kf6_datadir}/applications/%{appid}.desktop

%files -f bazzite-updater.lang
%license LICENSES/{BSD-3-Clause.txt,CC0-1.0.txt,GPL-2.0-or-later.txt,FSFAP.txt}
%doc README.md
%{_kf6_bindir}/bazzite-updater
%{_kf6_datadir}/applications/%{appid}.desktop
%{_kf6_metainfodir}/%{appid}.*.xml
%{_kf6_datadir}/icons/hicolor/scalable/apps/%{appid}.svg
%config(noreplace) /etc/bazzite-updater/config.ini
/etc/bazzite-updater/

%changelog
* Thu Feb 05 2026 Robert French
- Initial rpm build of Bazzite Updater
