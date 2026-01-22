// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KLocalizedString>
#include <QFileInfo>
#include <QJSValue>
#include <QProcess>
#include <QQmlEngine>

#include "utils.h"

using namespace Qt::Literals::StringLiterals;

struct osImage {
    Q_GADGET
    QML_VALUE_TYPE(osImage)

    Q_PROPERTY(QString name MEMBER m_imageName CONSTANT)
    Q_PROPERTY(QString vendor MEMBER m_imageVendor CONSTANT)
    Q_PROPERTY(QString ref MEMBER m_imageRef CONSTANT)
    Q_PROPERTY(QString tag MEMBER m_imageTag CONSTANT)
    Q_PROPERTY(QString branch MEMBER m_imageBranch CONSTANT)
    Q_PROPERTY(QString baseName MEMBER m_baseImageName CONSTANT)
    Q_PROPERTY(QString fedoraVersion MEMBER m_fedoraVersion CONSTANT)
    Q_PROPERTY(QString version MEMBER m_version CONSTANT)
    Q_PROPERTY(QString versionPretty MEMBER m_versionPretty CONSTANT)
    Q_PROPERTY(QVariantMap datePretty MEMBER m_datePretty CONSTANT)
    Q_PROPERTY(bool load_successful MEMBER m_isValid CONSTANT)

public:
    osImage() = default;
    static osImage fromJson(const QString &filePath);

    QString m_imageName;
    QString m_imageVendor;
    QString m_imageRef;
    QString m_imageTag;
    QString m_imageBranch;
    QString m_baseImageName;
    QString m_fedoraVersion;
    QString m_version;
    QString m_versionPretty;
    QVariantMap m_datePretty;
    bool m_isValid = false;
};

class RebaseHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(osImage currentImage READ currentImage CONSTANT)
    // Q_PROPERTY(bool rebaseValid READ rebaseValid WRITE checkRebaseValid NOTIFY rebaseValidChanged)

    osImage m_osImage_current;
    osImage m_osImage_new;
    bool m_rebaseValid = false;
    bool m_newIsCurrent = true;

public:
    RebaseHelper(QObject *parent = nullptr);

    osImage currentImage() const
    {
        return m_osImage_current;
    }

    // ROLLBACK
    Q_INVOKABLE void rollbackImage(QJSValue callback);

    // REBASE
};
