// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "other_utils.h"
#include "console.h"
#include "k_config.h"
#include "utils.h"

#include <QDate>
#include <QJsonDocument>
#include <QJsonObject>
#include <qjsonparseerror.h>
#include <qjsonvalue.h>
#include <qlogging.h>
#include <qprocess.h>
#include <qstandardpaths.h>
#include <qtmetamacros.h>

// TODO: Move into AppData
osImage osImage::fromJson(const QString &filePath)
{
    QFile json_file(filePath);
    osImage img;

    if (!json_file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open image-info.json at" << filePath;
        return img;
    }

    QByteArray fileData = json_file.readAll();
    json_file.close();

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(fileData, &parseError);

    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        qWarning() << "JSON Parse Error:" << parseError.errorString();
        return img;
    }

    QJsonObject obj = doc.object();

    img.m_imageName = obj.value(u"image-name"_s).toString();
    img.m_imageVendor = obj.value(u"image-vendor"_s).toString();
    img.m_imageRef = obj.value(u"image-ref"_s).toString();
    img.m_imageTag = obj.value(u"image-tag"_s).toString();
    img.m_imageBranch = obj.value(u"image-branch"_s).toString();
    img.m_baseImageName = obj.value(u"base-image-name"_s).toString();
    img.m_fedoraVersion = obj.value(u"fedora-version"_s).toString();
    img.m_version = obj.value(u"version"_s).toString();
    img.m_versionPretty = obj.value(u"version-pretty"_s).toString();
    {
        QString temp_year, temp_month, temp_day;

        // m_version has format of fedora-version.yyyyMMdd

        QString datePart = img.m_version.right(8);
        QDate date = QDate::fromString(datePart, u"yyyyMMdd"_s);

        if (date.isValid()) {
            temp_year = date.toString(u"yyyy"_s);
            temp_month = date.toString(u"MMMM"_s);
            temp_day = date.toString(u"d"_s);
        } else {
            temp_year = u"ERROR!"_s;
            temp_month = u"ERROR!"_s;
            temp_day = u"ERROR!"_s;
        }

        img.m_datePretty.insert(u"year"_s, temp_year);
        img.m_datePretty.insert(u"month"_s, temp_month);
        img.m_datePretty.insert(u"day"_s, temp_day);
    }
    img.m_isValid = true;
    return img;
}

OtherUtilsBackend::OtherUtilsBackend(QObject *parent)
    : QObject(parent)
{
    addToSteamAvailable = QFileInfo(u"/usr/bin/steamos-add-to-steam"_s).isExecutable();

    m_console = new Console::Model(this);

    QString path;
    {
        const QString primaryPath = u"/usr/share/ublue-os/image-info.json"_s;

        if (QFile::exists(primaryPath))
            path = primaryPath;
        else
            path = u"/run/host/usr/share/ublue-os/image-info.json"_s;
    }
    m_osImage_current = osImage::fromJson(path);
}

// ROLLBACK
void OtherUtilsBackend::rollbackImage(QJSValue callback)
{
    if (!callback.isCallable()) {
        qDebug() << "Callback is not callable, command run refused";
        return;
    }

    if (!appState.allowCommands()) {
        qDebug() << "Command called when not allowed, ignored";
        return;
    }

    appState.setRollbackRunning(true);

    auto cmd = configIni.getValue(u"Commands"_s, u"systemRollbackCommand"_s).split(u' ');

    auto onFinish = [=](int exit_code) {
        appState.setRollbackRunning(false);
        if (exit_code == 0)
            appState.setCommandSucceeded(true);

        callback.call({exit_code});
    };

    auto onError = [=, this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart)
            m_console->newLine(i18n("Rollback program was not found or failed to start."), Console::LogLevel::ErrorCritical);

        appState.setRollbackRunning(false);
        callback.call({1});
    };

    m_console->runProcess(cmd, onFinish, onError);
}

void OtherUtilsBackend::addToSteam(QJSValue callback)
{
    if (!callback.isCallable()) {
        qDebug() << "Callback is not callable, command run refused";
        return;
    }

    if (m_console->processRunning) {
        qDebug() << "Command called when not allowed, ignored";
        return;
    }

    const QStringList cmd = {u"/usr/bin/steamos-add-to-steam"_s, QStandardPaths::findExecutable(u"bazzite-updater"_s)};

    auto onFinish = [=, this](int exit_code) {
        if (exit_code == 0)
            m_console->newLine(i18n("If steam is open, you must restart it before Bazzite Updater will appear in your library."), Console::LogLevel::Info);

        callback.call({exit_code});
    };

    auto onError = [=, this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart)
            m_console->newLine(i18n("steamos-add-to-steam program was not found or failed to start."), Console::LogLevel::ErrorCritical);

        callback.call({1});
    };

    m_console->runProcess(cmd, onFinish, onError);
}
