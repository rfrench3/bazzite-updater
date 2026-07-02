// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "k_config.h"
#include <cassert>
#include <kconfiggroup.h>
#include <ksharedconfig.h>
#include <qdir.h>
#include <qjsondocument.h>
#include <qjsonvalue.h>
#include <qlogging.h>
#include <qstringview.h>

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
    QFile aboutData(u"/usr/share/bazzite-updater/OsKAboutData.json"_s);
    if (!aboutData.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open OsKAboutData";
        m_aboutOs[u"displayName"_s] = u"Failed to fetch information."_s;
    } else {
        QByteArray file = aboutData.readAll();
        QJsonDocument doc = QJsonDocument::fromJson(file);
        m_aboutOs = doc.object();

        // Process specific values
        QJsonValueRef version = m_aboutOs[u"version"_s];

        if (version.toString() == u"@VERSION@"_s) {
            if (m_osRelease.keys().contains(u"VERSION"_s))
                version = m_osRelease[u"VERSION"_s];
            else if (m_osRelease.keys().contains(u"VERSION"_s))
                version = m_osRelease[u"VERSION_ID"_s];
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

        m_osRelease.insert(key, value);
    }
}

ConfigIni::ConfigIni()
{
    KSharedConfigPtr config = KSharedConfig::openConfig(u"/usr/share/bazzite-updater/config.ini"_s, KConfig::SimpleConfig);
    KConfigGroup commandsGroup = config->group(u"Commands"_s);

    systemUpdateCommand = commandsGroup.readEntry(u"systemUpdateCommand"_s, u""_s);

    KConfigGroup aboutInfoGroup = config->group(u"AboutInfo"_s);

    osName = aboutInfoGroup.readEntry(u"name"_s, u""_s);
    osIconPath = aboutInfoGroup.readEntry(u"iconPath"_s, u""_s);
}
