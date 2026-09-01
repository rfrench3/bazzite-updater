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
#include <qobject.h>
#include <qstringview.h>
#include <qtenvironmentvariables.h>
#include <qvariant.h>

AppConfig::AppConfig()
{
    serviceHelperScript = findConfigFile(u"bazzite-updater/service-as-program.sh"_s);

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
    QFile aboutData(findConfigFile(u"bazzite-updater/KAboutData_OS.json"_s));
    if (!aboutData.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open KAboutData_OS";
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

        // If the desired icon does not exist, allow QML to fallback to qrc:/fallbackIcon
        if (!QFile(aboutOs[u"programLogo"_s].toString()).exists())
            aboutOs[u"programLogo"_s] = u""_s;

        auto copyright = aboutOs[u"copyrightStatement"_s].toString();
        int idx = copyright.indexOf(u"@CURRENT_YEAR@"_s);
        if (idx != -1) {
            copyright.replace(idx, 14, QString::number(QDate::currentDate().year()));
            aboutOs.insert(u"copyrightStatement"_s, copyright);
        }

        aboutData.close();
    }

    QFile rebaseFile(findConfigFile(u"bazzite-updater/rebase-targets.json"_s));
    if (!rebaseFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open rebase-targets.json";
        rebaseTargets[u"valid"_s] = false;

    } else {
        QByteArray file = rebaseFile.readAll();
        QJsonDocument doc = QJsonDocument::fromJson(file);
        rebaseTargets = doc.object();
        rebaseTargets[u"valid"_s] = true;
        rebaseFile.close();
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

// (ex: u"bazzite-updater/config.ini"_s) Returns the full path to the config file that should be used.
QString findConfigFile(const QString &relativePath)
{
    QStringList bases;

    /* do NOT check the home config path. Any app with home folder access could
     * run arbitrary code in place of the normal system update. Only look for
     * configs in the standard places under /etc and /usr
     */

    // bases.append(qEnvironmentVariable("XDG_CONFIG_HOME", QDir::homePath() + u"/.config"_s));

    bases.append({u"/etc"_s, u"/usr/local/etc"_s, u"/usr/etc"_s});

    // append XDG_CONFIG_DIRS last because any user (or malicious program run by the user) can change it
    if (auto xdg_config = qEnvironmentVariable("XDG_CONFIG_DIRS"); xdg_config.isEmpty())
        bases.append(u"/etc/xdg"_s);
    else
        bases.append(xdg_config.split(u':', Qt::SkipEmptyParts));

    for (const QString &dir : bases) {
        const QString path = QDir(dir).filePath(relativePath);
        QFile file(path);

        if (file.exists()) {
            if (file.open(QIODevice::ReadOnly))
                return path;
            else
                qWarning() << "Config found at " << path << " but could not open: " << file.errorString();
        }
    }
    qWarning() << "App Config file not found: " << relativePath;
    return u""_s;
}

namespace SingletonInternals
{

ConfigIni::ConfigIni()
{
    auto filepath = findConfigFile(u"bazzite-updater/config.ini"_s);
    auto base_path = QFileInfo(filepath).absolutePath();

    KSharedConfigPtr config = KSharedConfig::openConfig(filepath, KConfig::SimpleConfig);

    for (const QString &group : config->groupList()) {
        auto map = config->entryMap(group);

        QVariantMap groupMap;

        for (auto it = map.constBegin(); it != map.constEnd(); ++it) {
            const QString key = it.key();
            QString val = it.value();

            // convert relative paths to absolute form
            if (val.startsWith(u"./"_s))
                val = base_path + val.mid(1);

            groupMap.insert(key, val);
        }

        ini.insert(group, groupMap);
    }
}

QString VarMapPlus::getValue(const QString &group, const QString &key, const QString &fallback)
{
    if (!configIni.contains(group))
        return fallback;

    auto groupMap = configIni.value(group).toMap();

    if (!groupMap.contains(key))
        return fallback;

    return groupMap.value(key).toString();
}

}
