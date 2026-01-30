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

    QProcess rollback;
    Utils::startProcess(rollback, u"bazzite-rollback-helper"_s, {u"rollback"_s, u"-y"_s});
    rollback.waitForFinished();

    int exit_code = rollback.exitCode();

    m_appState->setRollbackRunning(false);
    if (exit_code == 0)
        m_appState->setCommandSucceeded(true);

    callback.call({exit_code});
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

    QProcess rebase;
    Utils::startProcess(rebase, u"bazzite-rollback-helper"_s, {u"rebase"_s, new_image, u"-y"_s});
    rebase.waitForFinished();

    if (rebase.exitCode() == 0)
        m_appState->setCommandSucceeded(true);

    m_appState->setRebaseRunning(false);
    callback.call({rebase.exitCode()});
}
