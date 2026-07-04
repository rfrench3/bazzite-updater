// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "rebase_helper.h"
#include "k_config.h"
#include "utils.h"

#include <QDate>
#include <QJsonDocument>
#include <QJsonObject>
#include <qlogging.h>
#include <qprocess.h>
#include <qtmetamacros.h>

// Async is not necessary for this function (probably)
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

RebaseHelperBackend::RebaseHelperBackend(QObject *parent)
    : QObject(parent)
{
    m_console = new Console::Model(this);
    best_driver = Gpu::Drivers::UNKNOWN;

    QString path;
    {
        const QString primaryPath = u"/usr/share/ublue-os/image-info.json"_s;

        if (QFile::exists(primaryPath))
            path = primaryPath;
        else
            path = u"/run/host/usr/share/ublue-os/image-info.json"_s;
    }
    m_osImage_current = osImage::fromJson(path);

    setGpuDrivers();
}

void RebaseHelperBackend::setGpuDrivers()
{
    const auto path = u"/usr/libexec/bazzite_detect_nvidia_support_status"_s;

    if (!QFile::exists(path))
        return;

    QProcess *check_nvidia = new QProcess(this);

    connect(check_nvidia, &QProcess::errorOccurred, [check_nvidia](QProcess::ProcessError err) {
        qWarning() << u"setGpuDrivers error:"_s << err << check_nvidia->errorString();
        check_nvidia->deleteLater();
    });

    connect(check_nvidia, &QProcess::finished, [this, check_nvidia]() {
        if (check_nvidia->exitCode() != 0) {
            return;
        }

        QString output = QString::fromUtf8(check_nvidia->readAllStandardOutput()).trimmed();

        if (output == u"supported"_s)
            best_driver = Gpu::Drivers::NVIDIA_OPEN;
        else if (output == u"legacy"_s)
            best_driver = Gpu::Drivers::NVIDIA;
        else if (output == u"unsupported"_s)
            best_driver = Gpu::Drivers::UNSUPPORTED;
        else if (output.isEmpty())
            best_driver = Gpu::Drivers::BASE;
        else
            best_driver = Gpu::Drivers::UNKNOWN;

        Q_EMIT recommendedDriverChanged();
        check_nvidia->deleteLater();
        return;
    });

    Utils::startProcess(check_nvidia, path, {});
}

// ROLLBACK
void RebaseHelperBackend::rollbackImage(QJSValue callback)
{
    if (!callback.isCallable()) {
        qDebug() << "Callback is not callable, command run refused";
        return;
    }
    if (!appState()->allowCommands()) {
        qDebug() << "Command called when not allowed, ignored";
        return;
    }

    appState()->setRollbackRunning(true);

    auto cmd = configIni.getValue(u"Commands"_s, u"systemRollbackCommand"_s).split(u' ');

    auto onFinish = [=](int exit_code) {
        appState()->setRollbackRunning(false);
        if (exit_code == 0)
            appState()->setCommandSucceeded(true);

        callback.call({exit_code});
    };

    auto onError = [=](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart)
            m_console->newLine(i18n("Rollback program was not found or failed to start."), Console::LogLevel::ErrorCritical);

        appState()->setRollbackRunning(false);
        callback.call({1});
    };

    m_console->runProcess(cmd, onFinish, onError);
}
