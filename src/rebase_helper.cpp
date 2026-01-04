// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "rebase_helper.h"

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

RebaseHelper::RebaseHelper(QObject *parent)
    : QObject(parent)
{
    QString path;
    if (isFlatpak())
        path = QStringLiteral("/run/host/usr/share/ublue-os/image-info.json");
    else
        path = QStringLiteral("/usr/share/ublue-os/image-info.json");

    // HACK FOR DISTROBOX TESTING
    path = QStringLiteral("/run/host/usr/share/ublue-os/image-info.json");

    QFile file_current_image(path);

    if (file_current_image.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QByteArray fileData = file_current_image.readAll();
        m_current = parseImageJson(fileData);

        file_current_image.close();

        qDebug() << "Loaded image info for:" << m_current.m_imageName;
    } else {
        qWarning() << "Failed to open image-info.json at" << path;
    }

    // Something has gone wrong
    if (!m_current.m_isValid) {
        // TODO: prevent interacting with page
        qWarning() << "Current is not valid";
    }

    Q_EMIT currentImageInitialized();
}

OsImage RebaseHelper::currentImage() const
{
    return m_current;
}

OsImage RebaseHelper::parseImageJson(const QByteArray &jsonData)
{
    OsImage img;

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(jsonData, &parseError);

    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        qWarning() << "JSON Parse Error:" << parseError.errorString();
        img.m_isValid = false;
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

    img.m_isValid = true;

    return img;
}
