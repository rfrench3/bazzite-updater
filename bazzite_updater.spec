%global orgname io.github.rfrench3.bazzite_updater

Name:           bazzite_updater
Version:        0.1
Release:        1%{?dist}
License:        GPL-2.0-or-later
Summary:        Update your Bazzite system
URL:            https://github.com/rfrench3/bazzite_updater
BuildRequires:  desktop-file-utils
BuildRequires:  libappstream-glib

BuildRequires:  cmake(Qt6Core)
BuildRequires:  cmake(Qt6Gui)
BuildRequires:  cmake(Qt6Qml)
BuildRequires:  cmake(Qt6QuickControls2)
BuildRequires:  cmake(Qt6Svg)
BuildRequires:  cmake(Qt6Widgets)

BuildRequires:  cmake(KF6Kirigami)
BuildRequires:  cmake(KF6CoreAddons)
BuildRequires:  cmake(KF6Config)
BuildRequires:  cmake(KF6I18n)
BuildRequires:  cmake(KF6IconThemes)
BuildRequires:  cmake(KF6KirigamiAddons)
#BuildRequires:  cmake(Plasma)

Requires:       kf6-kuserfeedback%{?_isa}
Requires:       kf6-kirigami%{?_isa}
Requires:       kf6-kirigami-addons%{?_isa}

Provides:       bazzite_updater = %{version}-%{release}

%check
appstream-util validate-relax --nonet %{buildroot}%{_kf6_metainfodir}/%{orgname}.*.xml || :
desktop-file-validate %{buildroot}%{_kf6_datadir}/applications/%{orgname}.desktop

%license LICENSES/{BSD-3-Clause.txt,CC0-1.0.txt,GPL-2.0-or-later.txt,FSFAP.txt}
%doc README.md
%{_kf6_bindir}/bazzite_updater
%{_kf6_datadir}/applications/%{orgname}.desktop
%{_kf6_metainfodir}/%{orgname}.*.xml
