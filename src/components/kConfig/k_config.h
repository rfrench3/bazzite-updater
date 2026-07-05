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

namespace SingletonInternals
{

class VarMapPlus : public QVariantMap
{
public:
    // much more convenient for C++
    static QString getValue(const QString &group, const QString &key, const QString &fallback = QString());
};

struct ConfigIni {
    static ConfigIni &instance()
    {
        static ConfigIni s;
        return s;
    } // instance

    ConfigIni(const ConfigIni &) = delete;
    ConfigIni &operator=(const ConfigIni &) = delete;

private:
    ConfigIni();
    ~ConfigIni()
    {
    }

public:
    VarMapPlus ini;
};

}

inline SingletonInternals::VarMapPlus configIni = SingletonInternals::ConfigIni::instance().ini;

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
    Q_PROPERTY(QVariantMap ini READ config CONSTANT)

    void setupOsRelease(QFile &file);

    QJsonObject aboutOs;
    QJsonObject osRelease;

    // Full path for service-as-program.sh
    QString serviceHelperScript;

    QVariantMap config() const
    {
        return configIni;
    }

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
