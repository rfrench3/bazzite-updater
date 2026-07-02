// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "k_config.h"
#include <cassert>
#include <kconfiggroup.h>
#include <ksharedconfig.h>
#include <qcontainerfwd.h>
#include <qdir.h>
#include <qevent.h>
#include <qjsondocument.h>
#include <qjsonvalue.h>
#include <qlogging.h>
#include <qstringview.h>
#include <qtenvironmentvariables.h>

AppConfig *AppConfig::m_instance = nullptr;

AppConfig::AppConfig()
{
    if (m_instance == nullptr)
        m_instance = this;
    else
        qWarning() << "AppState was constructed when an instance already exists!";

    // Store the OsRelease file into a QJsonObject
    QFile os_release(u"/etc/os-release"_s);
    if (os_release.open(QIODevice::ReadOnly | QIODevice::Text)) {
        setupOsRelease(os_release);
        os_release.close();
    } else {
        QFile os_release(u"/usr/lib/os-release"_s);
        if (os_release.open(QIODevice::ReadOnly | QIODevice::Text)) {
            setupOsRelease(os_release);
            os_release.close();
        } else {
            qWarning() << "Failed to open any os-release";
        }
    }

    // Store the KAboutData object into a QJsonObject
    QFile aboutData(findConfigFile(u"bazzite-updater/OsKAboutData.json"_s));
    if (!aboutData.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open OsKAboutData";
        aboutOs[u"displayName"_s] = u"Failed to fetch information."_s;
    } else {
        QByteArray file = aboutData.readAll();
        QJsonDocument doc = QJsonDocument::fromJson(file);
        aboutOs = doc.object();

        // Process specific values
        if (aboutOs[u"version"_s].toString() == u"@VERSION@"_s) {
            if (osRelease.keys().contains(u"VERSION"_s))
                aboutOs.insert(u"version"_s, osRelease[u"VERSION"_s]);
            else if (osRelease.keys().contains(u"VERSION_ID"_s))
                aboutOs.insert(u"version"_s, osRelease[u"VERSION_ID"_s]);
            else
                aboutOs.insert(u"version"_s, u"Unknown version"_s);
        }

        if (aboutOs[u"license"_s].toString() == u"@Apache-2.0@"_s) {
            // TODO: insert the entire apache 2.0 license
            aboutOs[u"license"_s] = u"https://www.apache.org/licenses/LICENSE-2.0.txt"_s;
        }

        auto copyright = aboutOs[u"copyrightStatement"_s].toString();
        int idx = copyright.indexOf(u"@CURRENT_YEAR@"_s);
        if (idx != -1) {
            copyright.replace(idx, 14, QString::number(QDate::currentDate().year()));
            aboutOs.insert(u"copyrightStatement"_s, copyright);
        }

        aboutData.close();
    }
}

// Convert the key=value format of os-release into a QJsonObject entirely made of QStrings
void AppConfig::setupOsRelease(QFile &file)
{
    while (!file.atEnd()) {
        QByteArray arr = file.readLine();

        auto line = QString::fromUtf8(arr).trimmed();

        if (line.isEmpty() || line.startsWith(u'#'))
            continue;

        int split = line.indexOf(u'=');
        if (split == -1)
            continue;

        auto key = line.left(split);
        auto value = line.mid(split + 1);

        // Remove surrounding quotations, if there are any
        if (value.length() >= 2 && ((value.startsWith(u'"') && value.endsWith(u'"')) || (value.startsWith(u'\'') && value.endsWith(u'\'')))) {
            value = value.sliced(1, value.length() - 2);
        }

        osRelease.insert(key, value);
    }
}

ConfigIni::ConfigIni()
{
    KSharedConfigPtr config = KSharedConfig::openConfig(findConfigFile(u"bazzite-updater/config.ini"_s), KConfig::SimpleConfig);
    KConfigGroup commandsGroup = config->group(u"Commands"_s);

    systemUpdateCommand = commandsGroup.readEntry(u"systemUpdateCommand"_s, u""_s);

    KConfigGroup aboutInfoGroup = config->group(u"AboutInfo"_s);

    osName = aboutInfoGroup.readEntry(u"name"_s, u""_s);
    osIconPath = aboutInfoGroup.readEntry(u"iconPath"_s, u""_s);
}

// (ex: u"bazzite-updater/config.ini"_s) Returns the full path to the config file that should be used.
QString findConfigFile(const QString &relativePath)
{
    QStringList bases;

    bases.append(qEnvironmentVariable("XDG_CONFIG_HOME", QDir::homePath() + u"/.config"_s));

    // A better implementation would check XDG_CONFIG_DIRS, /etc/xdg here

    bases.append({u"/etc"_s, u"/usr/local/etc"_s, u"/usr/etc"_s});

    for (const QString &dir : bases) {
        const QString path = QDir(dir).filePath(relativePath);
        QFile file(path);
        if (file.open(QIODevice::ReadOnly))
            return path;
    }
    qWarning() << "App Config file not found.";
    return u""_s;
}
