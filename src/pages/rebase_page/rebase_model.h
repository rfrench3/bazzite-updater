// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include "console.h"

#include <qcontainerfwd.h>
#include <qjsengine.h>
#include <qjsonarray.h>
#include <qjsonvalue.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qqmlintegration.h>
#include <qset.h>
#include <qtclasshelpermacros.h>
#include <qtmetamacros.h>
#include <qvariant.h>

/*
 * TODO: current issues
 * - bootc switch silently continues in the background on app close
 * - rpm-ostree not yet tested
 * - uses pkexec, run0 would be greatly preferable
 * - creates multiple password prompts (check bootc status for bootc compatibility, runs bootc/rpm-ostree rebase which need another)
 */

// Required for QVariantSet.contains(other QVariantSet) to work
inline size_t qHash(const QVariant &key, size_t seed = 0) noexcept
{
    if (key.canConvert<QString>()) {
        return qHash(key.toString(), seed);
    }

    return qHash(key.userType(), seed);
}

using QVariantSet = QSet<QVariant>;

QVariantList setToList(const QVariantSet &set);

// Each QVariant in targets is: { url, name, features[], tags[] }

class RebaseModel : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_DISABLE_COPY_MOVE(RebaseModel)
    RebaseModel();

public: // singleton methods
    static RebaseModel *instance()
    {
        static RebaseModel *s_instance = new RebaseModel();
        return s_instance;
    }

    static RebaseModel *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
    {
        Q_UNUSED(jsEngine)
        RebaseModel *instancePtr = instance();
        qmlEngine->setObjectOwnership(instancePtr, QQmlEngine::CppOwnership);
        return instancePtr;
    }

public:
    Console::Model *m_console;
    Q_PROPERTY(Console::Model *consoleModel MEMBER m_console CONSTANT)

    QVariantList targets;
    Q_PROPERTY(QVariantList targets MEMBER targets CONSTANT)

    QVariantList filtered;
    Q_PROPERTY(QVariantList filtered MEMBER filtered NOTIFY filteredChanged)
    Q_SIGNAL void filteredChanged();
    void updateFiltered();

    // obtained from the list of rebase targets and image-info.json
    QVariant currentImage;
    Q_PROPERTY(QVariant currentImage MEMBER currentImage CONSTANT)

    enum RebaseProgram {
        UNDEFINED,
        BOOTC,
        RPM_OSTREE
    };
    RebaseProgram rebaseProgram = UNDEFINED;
    void checkRebaseProgram();
    Q_INVOKABLE void runRebase(QString image, QJSValue callback);

    // change this to update filtered
    QVariantSet m_features;
    Q_PROPERTY(QVariantList features READ features WRITE setFeatures NOTIFY featuresChanged)
    QVariantList features() const
    {
        return setToList(m_features);
    }
    void setFeatures(QVariantList val);
    Q_SIGNAL void featuresChanged();

    // use skopeo list-tags and trim sha256 entries
    Q_INVOKABLE void getAllTags(QString url, QJSValue callback = QJSValue());
};
