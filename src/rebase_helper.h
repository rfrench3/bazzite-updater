// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KLocalizedString>
#include <QFileInfo>
#include <QJSValue>
#include <QProcess>
#include <QQmlEngine>

struct OsImage {
    Q_GADGET
    QML_VALUE_TYPE(OsImage)

    Q_PROPERTY(QString name MEMBER m_imageName CONSTANT)
    Q_PROPERTY(QString vendor MEMBER m_imageVendor CONSTANT)
    Q_PROPERTY(QString ref MEMBER m_imageRef CONSTANT)
    Q_PROPERTY(QString tag MEMBER m_imageTag CONSTANT)
    Q_PROPERTY(QString branch MEMBER m_imageBranch CONSTANT)
    Q_PROPERTY(QString baseName MEMBER m_baseImageName CONSTANT)
    Q_PROPERTY(QString fedoraVersion MEMBER m_fedoraVersion CONSTANT)
    Q_PROPERTY(QString version MEMBER m_version CONSTANT)
    Q_PROPERTY(QString versionPretty MEMBER m_versionPretty CONSTANT)
    Q_PROPERTY(bool load_successful MEMBER m_isValid CONSTANT)

public:
    QString m_imageName = QStringLiteral("NULL");
    QString m_imageVendor = QStringLiteral("NULL");
    QString m_imageRef = QStringLiteral("NULL");
    QString m_imageTag = QStringLiteral("NULL");
    QString m_imageBranch = QStringLiteral("NULL");
    QString m_baseImageName = QStringLiteral("NULL");
    QString m_fedoraVersion = QStringLiteral("NULL");
    QString m_version = QStringLiteral("NULL");
    QString m_versionPretty = QStringLiteral("NULL");
    bool m_isValid = false;
};

Q_DECLARE_METATYPE(OsImage);

class RebaseHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(OsImage currentImage READ currentImage NOTIFY currentImageInitialized)

    OsImage m_current;
    OsImage m_new;

    static bool isFlatpak()
    {
        return QFileInfo::exists(QStringLiteral("/.flatpak-info"));
    }

    OsImage parseImageJson(const QByteArray &jsonData);

public:
    RebaseHelper(QObject *parent = nullptr);

    // Q_INVOKABLE void runRebase(QJSValue callback = QJSValue());

    OsImage currentImage() const;
    Q_SIGNAL void currentImageInitialized();

    // void setNewImage(const QString &consoleText);
    // Q_SIGNAL void newImageChanged();
};
