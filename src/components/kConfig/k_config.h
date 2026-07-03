// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KConfig>
#include <kaboutdata.h>
#include <kconfig.h>
#include <ksharedconfig.h>
#include <qcontainerfwd.h>
#include <qfile.h>
#include <qjsengine.h>
#include <qjsonobject.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qqmlintegration.h>
#include <qtclasshelpermacros.h>
#include <qtmetamacros.h>
#include <qtpreprocessorsupport.h>

using namespace Qt::Literals::StringLiterals;

// Entries that cannot be found are left empty
struct ConfigIni {
    Q_GADGET
public:
    QString systemUpdateCommand;
    QString osName;
    QString osIconPath;

    Q_PROPERTY(QString systemUpdateCommand MEMBER systemUpdateCommand CONSTANT)
    Q_PROPERTY(QString osName MEMBER osName CONSTANT)
    Q_PROPERTY(QString osIconPath MEMBER osIconPath CONSTANT)

public:
    ConfigIni();
};

class AppConfig : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_DISABLE_COPY_MOVE(AppConfig)
    AppConfig();

public: // singleton methods
    static AppConfig *instance()
    {
        static AppConfig *s_instance = new AppConfig();
        return s_instance;
    }

    static AppConfig *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
    {
        Q_UNUSED(jsEngine)
        AppConfig *instancePtr = instance();
        qmlEngine->setObjectOwnership(instancePtr, QQmlEngine::CppOwnership);
        return instancePtr;
    }

public:
    Q_PROPERTY(QJsonObject osAboutData MEMBER aboutOs CONSTANT)
    Q_PROPERTY(QJsonObject osRelease MEMBER osRelease CONSTANT)
    Q_PROPERTY(ConfigIni configIni MEMBER configIni CONSTANT)

    void setupOsRelease(QFile &file);

    QJsonObject aboutOs;
    QJsonObject osRelease;
    ConfigIni configIni;

    Q_INVOKABLE QVariantMap osReleaseVarMap() const
    {
        return osRelease.toVariantMap();
    }
};

inline AppConfig *appConfig()
{
    return AppConfig::instance();
}

QString findConfigFile(const QString &relativePath);
