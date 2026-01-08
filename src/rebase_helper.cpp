// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "rebase_helper.h"

#include <QDate>
#include <QJsonDocument>
#include <QJsonObject>

// cat /usr/share/ublue-os/image-info.json
// {
//     "image-name": "bazzite-dx",
//     "image-vendor": "ublue-os",
//     "image-ref": "ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-dx",
//     "image-tag": "stable",
//     "image-branch": "stable",
//     "base-image-name": "kinoite",
//     "fedora-version": "43",
//     "version": "43.20251210",
//     "version-pretty": "Stable (F43.20251210)"
// }

// skopeo list-tags docker://ghcr.io/ublue-os/bazzite | grep -- "stable-" | sort -rV

OsImage OsImage::fromJson(const QString &filePath)
{
    QFile json_file(filePath);
    OsImage img;

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

    img.m_imageName = obj.value(QStringLiteral("image-name")).toString();
    img.m_imageVendor = obj.value(QStringLiteral("image-vendor")).toString();
    img.m_imageRef = obj.value(QStringLiteral("image-ref")).toString();
    img.m_imageTag = obj.value(QStringLiteral("image-tag")).toString();
    img.m_imageBranch = obj.value(QStringLiteral("image-branch")).toString();
    img.m_baseImageName = obj.value(QStringLiteral("base-image-name")).toString();
    img.m_fedoraVersion = obj.value(QStringLiteral("fedora-version")).toString();
    img.m_version = obj.value(QStringLiteral("version")).toString();
    img.m_versionPretty = obj.value(QStringLiteral("version-pretty")).toString();
    {
        QString temp_year, temp_month, temp_day;

        // m_version has format of fedora-version.yyyyMMdd

        QString datePart = img.m_version.right(8);
        QDate date = QDate::fromString(datePart, QStringLiteral("yyyyMMdd"));

        if (date.isValid()) {
            temp_year = date.toString(QStringLiteral("yyyy"));
            temp_month = date.toString(QStringLiteral("MMMM"));
            temp_day = date.toString(QStringLiteral("d"));
        } else {
            temp_year = QStringLiteral("ERROR!");
            temp_month = QStringLiteral("ERROR!");
            temp_day = QStringLiteral("ERROR!");
        }

        img.m_datePretty.insert(QStringLiteral("year"), temp_year);
        img.m_datePretty.insert(QStringLiteral("month"), temp_month);
        img.m_datePretty.insert(QStringLiteral("day"), temp_day);
    }
    img.m_isValid = true;
    return img;
}

RebaseHelper::RebaseHelper(QObject *parent)
    : QObject(parent)
{
    QString path;
    {
        const QString primaryPath = QStringLiteral("/usr/share/ublue-os/image-info.json");

        if (QFile::exists(primaryPath))
            path = primaryPath;
        else
            path = QStringLiteral("/run/host/usr/share/ublue-os/image-info.json");
    }
    m_current = OsImage::fromJson(path);
}

QStringList RebaseHelper::listImages() const
{
    QStringList images;

    // TODO: make this
    return images;
}

// Handles sandboxing such as Flatpak
void RebaseHelper::startProcess(QProcess *process, const QString &cmd, const QStringList &args)
{
    if (isFlatpak()) {
        QStringList hostArgs;
        hostArgs << QStringLiteral("--host") << cmd << args;
        process->start(QStringLiteral("flatpak-spawn"), hostArgs);
    } else {
        process->start(cmd, args);
    }
}

void RebaseHelper::startProcess(QProcess &process, const QString &cmd, const QStringList &args)
{
    startProcess(&process, cmd, args);
}

void RebaseHelper::checkRebaseValid()
{
    Q_EMIT rebaseValidChanged();
}

void RebaseHelper::compareCurrentNew()
{
    if (m_current.m_imageName == m_new.m_imageName && m_current.m_imageVendor == m_new.m_imageVendor && m_current.m_imageTag == m_new.m_imageTag)
        m_newIsCurrent = true;
    else
        m_newIsCurrent = false;
}
