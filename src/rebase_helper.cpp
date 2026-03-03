// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "rebase_helper.h"

#include <QDate>
#include <QJsonDocument>
#include <QJsonObject>

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

RebaseHelper::RebaseHelper(QObject *parent)
    : QObject(parent)
{
    QString path;
    {
        const QString primaryPath = u"/usr/share/ublue-os/image-info.json"_s;

        if (QFile::exists(primaryPath))
            path = primaryPath;
        else
            path = u"/run/host/usr/share/ublue-os/image-info.json"_s;
    }
    m_osImage_current = osImage::fromJson(path);

    m_gpu_drivers = checkNvidiaSupport();
}

// NOTE: This blocks the UI until there's a return.
// It should be fast, though
QString RebaseHelper::checkNvidiaSupport()
{
    QProcess check_nvidia;
    Utils::startProcess(check_nvidia, u"/usr/libexec/bazzite_detect_nvidia_support_status"_s, {});
    check_nvidia.waitForFinished();

    if (check_nvidia.exitCode() != 0)
        return u""_s;

    QString output = QString::fromStdString(check_nvidia.readAllStandardOutput().toStdString()).trimmed();

    if (output == u"supported"_s)
        return u"nvidia"_s;
    if (output == u"legacy"_s)
        return u"nvidia-open"_s;
    if (output == u"unsupported"_s)
        return i18n("unsupported");
    if (!output.isEmpty())
        return i18nc("do not translate nvidia or nvidia-open.", "not nvidia or nvidia-open");
    else
        return u""_s;
}

void RebaseHelper::setAppState(AppState *appState)
{
    m_appState = appState;
}

// ROLLBACK
void RebaseHelper::rollbackImage(QJSValue callback)
{
    if (!callback.isCallable()) {
        qDebug() << "Callback is not callable, command run refused";
        return;
    }
    if (!m_appState->allowCommands()) {
        qDebug() << "Command called when not allowed, ignored";
        return;
    }

    m_appState->setRollbackRunning(true);

    QProcess *rollback = new QProcess();
    Utils::startProcess(rollback, u"bazzite-rollback-helper"_s, {u"rollback"_s, u"-y"_s});

    connect(rollback, &QProcess::finished, [=]() {
        int exit_code = rollback->exitCode();

        m_appState->setRollbackRunning(false);
        if (exit_code == 0)
            m_appState->setCommandSucceeded(true);

        callback.call({exit_code});
        rollback->deleteLater();
    });

    connect(rollback, &QProcess::errorOccurred, [=](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            qWarning() << "bazzite-rollback-helper not found or failed to start";
            m_appState->setRollbackRunning(false);
            callback.call({1});
            rollback->deleteLater();
        }
    });
}

// REBASE
void RebaseHelper::rebaseImage(const QString new_image, QJSValue callback)
{
    if (!callback.isCallable()) {
        qDebug() << "Callback is not callable, command run refused";
        return;
    }
    if (!m_appState->allowCommands()) {
        qDebug() << "Command called when not allowed, ignored";
        return;
    }

    m_appState->setRebaseRunning(true);

    QProcess *rebase = new QProcess();
    Utils::startProcess(rebase, u"bazzite-rollback-helper"_s, {u"rebase"_s, new_image, u"-y"_s});

    connect(rebase, &QProcess::finished, [=]() {
        if (rebase->exitCode() == 0)
            m_appState->setCommandSucceeded(true);

        m_appState->setRebaseRunning(false);
        callback.call({rebase->exitCode()});
        rebase->deleteLater();
    });

    connect(rebase, &QProcess::errorOccurred, [=](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            qWarning() << "bazzite-rollback-helper not found or failed to start";
            m_appState->setRebaseRunning(false);
            callback.call({1});
            rebase->deleteLater();
        }
    });
}
