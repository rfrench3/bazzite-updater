// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KLocalizedString>
#include <QFileInfo>
#include <QJSValue>
#include <QProcess>
#include <QQmlEngine>
#include <qcontainerfwd.h>

using namespace Qt::Literals::StringLiterals;

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
    Q_PROPERTY(QVariantMap datePretty MEMBER m_datePretty CONSTANT)
    Q_PROPERTY(bool load_successful MEMBER m_isValid CONSTANT)

public:
    OsImage() = default;
    static OsImage fromJson(const QString &filePath);

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

Q_DECLARE_METATYPE(OsImage);

class RebaseHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(OsImage currentImage READ currentImage CONSTANT)
    // Q_PROPERTY(bool rebaseValid READ rebaseValid WRITE checkRebaseValid NOTIFY rebaseValidChanged)

    OsImage m_current;
    OsImage m_new;
    bool m_rebaseValid = false;
    bool m_newIsCurrent = true;

    // TODO: put these in a parent class shared with Utils (and rename Utils to SystemUpdate)
    static void startProcess(QProcess *process, const QString &cmd, const QStringList &args);
    static void startProcess(QProcess &process, const QString &cmd, const QStringList &args);
    static bool isFlatpak()
    {
        return QFileInfo::exists(u"/.flatpak-info"_s);
    }

public:
    RebaseHelper(QObject *parent = nullptr);

    void compareCurrentNew();

    bool rebaseValid() const
    {
        return m_rebaseValid;
    }
    void checkRebaseValid();
    Q_SIGNAL void rebaseValidChanged();

    // (QJSValue callback = QJSValue()); callback if needed later

    // NOTE: The image variants are hardcoded like they are in bazzite rollback helper,
    //       Check src/resources/variants.json
    Q_INVOKABLE QStringList listImages() const;
    //
    // Q_INVOKABLE void rollbackImage();
    // Q_INVOKABLE void rebaseImage(const QString &new_image);
    // Q_INVOKABLE void customImage(const QString &new_provider);

    OsImage currentImage() const
    {
        return m_current;
    }
};
