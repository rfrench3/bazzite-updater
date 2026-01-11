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
    m_current = OsImage::fromJson(path);
}

QStringList RebaseHelper::listImages() const
{
    QStringList images;

    // TODO: make this
    return images;
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
