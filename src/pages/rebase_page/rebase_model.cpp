// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "rebase_model.h"
#include "console.h"
#include "k_config.h"
#include "other_utils.h"
#include "utils.h"
#include <qguiapplication.h>
#include <qhashfunctions.h>
#include <qjsengine.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qjsonvalue.h>
#include <qjsvalue.h>
#include <qprocess.h>
#include <qqmlengine.h>
#include <qtconcurrentrun.h>
#include <qvariant.h>

inline const QString KeyUrl = u"url"_s;
inline const QString KeyName = u"name"_s;
inline const QString KeyFeatures = u"features"_s;
inline const QString KeyImages = u"images"_s;
inline const QString KeyTags = u"tags"_s;

// Only available for the Current system image
inline const QString KeyCurrentTag = u"currentTag"_s;

// convert set to list
QVariantList setToList(const QVariantSet &set)
{
    QVariantList list;
    list.reserve(set.size());
    for (const QVariant &item : set) {
        list.append(item);
    }
    return list;
}

RebaseModel::RebaseModel()
{
    m_console = new Console::Model(this);

    for (const QVariant &item : appConfig()->rebaseTargets) {
        auto obj = item.toJsonObject();

        auto imgs = obj.value(KeyImages).toArray();
        auto url = obj.value(KeyUrl).toString();

        // find the current image to store its features.
        // Incompatible images cannot be shown.
        bool currentFound = false;
        for (const QJsonValue &img : imgs) {
            auto imgObj = img.toObject();

            auto imgName = imgObj.value(KeyName).toString();
            auto imgFeatures = imgObj.value(KeyFeatures).toArray();

            if (otherUtilsBackend->currentImage().m_imageRef == u"%1/%2"_s.arg(url).arg(imgName)) {
                imgObj.insert(KeyUrl, url);
                imgObj.insert(KeyCurrentTag, otherUtilsBackend->currentImage().m_imageBranch);
                currentFound = true;
                currentImage = imgObj;
                break;
            }
        }

        // Create a fallback image
        if (!currentFound) {
            QJsonObject obj;
            auto img = otherUtilsBackend->currentImage();
            int sep = img.m_imageRef.lastIndexOf(u'/');
            obj.insert(KeyUrl, img.m_imageRef.left(sep));
            obj.insert(KeyName, img.m_imageRef.mid(sep + 1));
            obj.insert(KeyTags, QJsonArray({img.m_imageBranch}));
            obj.insert(KeyCurrentTag, img.m_imageBranch);
            obj.insert(KeyFeatures, QJsonArray());
            currentImage = obj;
        }

        for (const QJsonValue &img : imgs) {
            auto imgObj = img.toObject();
            auto imgFeatures = imgObj.value(KeyFeatures).toArray();

            if (currentFound) {
                auto currentFeatures = currentImage.toJsonObject().value(KeyFeatures).toArray();

                bool currentGnome = currentFeatures.contains(u"gnome"_s);
                bool currentKde = currentFeatures.contains(u"kde"_s);
                bool imgGnome = imgFeatures.contains(u"gnome"_s);
                bool imgKde = imgFeatures.contains(u"kde"_s);

                // hide gnome if kde, hide kde if gnome
                if ((currentKde && imgGnome) || (currentGnome && imgKde))
                    continue;

                if (currentFound && img.toObject().value(u"features"_s).toArray() == currentFeatures)
                    continue;
            }

            imgObj.insert(KeyUrl, url);
            targets.append(imgObj);
        }
    }

    filtered = targets;
}

void RebaseModel::setFeatures(QVariantList features)
{
    m_features.clear();
    for (const QVariant &item : features)
        m_features.insert(item);

    updateFiltered();
    Q_EMIT featuresChanged();
}

void RebaseModel::updateFiltered()
{
    filtered.clear();

    if (m_features.isEmpty()) {
        filtered = targets;
    } else {
        for (const QVariant &img : targets) {
            auto obj = img.toJsonObject();

            QVariantSet img_feats;
            for (const QJsonValue &item : obj.value(KeyFeatures).toArray()) {
                img_feats.insert(item.toVariant());
            }

            if (img_feats.contains(m_features)) {
                filtered.append(img);
            }
        }
    }

    Q_EMIT filteredChanged();
}

void RebaseModel::runRebase(QString image, QJSValue callback = QJSValue())
{
    if (!appState.allowCommands()) {
        return;
    }

    checkRebaseProgram();

    if (rebaseProgram == UNDEFINED) {
        callback.call({1});
        return;
    }

    auto onFinish = [=, this](int exit_code) {
        const auto conclude = [=](int code, bool command) {
            callback.call({code});
            appState.setRebaseRunning(false);
            appState.setCommandSucceeded(command);
            return;
        };

        // Check for errors
        if (exit_code != 0) {
            conclude(1, false);
            qWarning() << "Rebase failed with exit code " << exit_code;
            m_console->newLine(u"The rebase has failed. Read the above output for more details."_s, Console::LogLevel::Error);
            return;
        }
        conclude(0, true);
    };

    auto onError = [=](QProcess::ProcessError error) {
        qWarning() << "Rebase errored with ProcessError " << error;
        callback.call({1});
        appState.setRebaseRunning(false);
    };

    appState.setRebaseRunning(true);

    // TODO: ideally this would use run0
    // https://github.com/bootc-dev/bootc/issues/2422
    QStringList program{u"pkexec"_s};

    if (rebaseProgram == RPM_OSTREE) {
        program << u"rpm-ostree rebase %1"_s.arg(image);
    } else {
        if (image.contains(u"docker://"_s))
            image = image.mid(image.indexOf(u"docker://"_s) + 9);
        program << u"bootc switch --enforce-container-sigpolicy %1"_s.arg(image);
    }

    // TODO: potentially try the default "bazzite" password before prompting user, if possible?
    m_console->runProcess(program, onFinish, onError);
}

// TODO: Move to src/components/data and make async
void RebaseModel::checkRebaseProgram()
{
    const bool hasBootc = !QStandardPaths::findExecutable(QStringLiteral("bootc")).isEmpty();
    const bool hasRpmOstree = !QStandardPaths::findExecutable(QStringLiteral("rpm-ostree")).isEmpty();

    if (!hasBootc && !hasRpmOstree) {
        rebaseProgram = UNDEFINED;
        return;
    }
    if (hasBootc && !hasRpmOstree) {
        rebaseProgram = BOOTC;
        return;
    }
    if (!hasBootc && hasRpmOstree) {
        rebaseProgram = RPM_OSTREE;
        return;
    }

    // Avoids bootc status needing root privileges
    const bool hasBootcHelper = !QStandardPaths::findExecutable(QStringLiteral("bootc-status-json")).isEmpty();

    QProcess proc;

    if (hasBootcHelper)
        proc.start(QStringLiteral("bootc-status-json"));
    else
        proc.start(QStringLiteral("run0"), {QStringLiteral("bootc"), QStringLiteral("status"), QStringLiteral("--json")});

    bool bootedIncompatible = false;
    if (proc.waitForStarted() && proc.waitForFinished(-1) && proc.exitCode() == 0) {
        const QByteArray out = proc.readAllStandardOutput();

        const QJsonObject booted = QJsonDocument::fromJson(out).object().value(u"status").toObject().value(u"booted").toObject();
        const QJsonValue incompatible = booted.value(u"incompatible");
        bootedIncompatible = incompatible.isBool() && incompatible.toBool();
    }

    rebaseProgram = bootedIncompatible ? RPM_OSTREE : BOOTC;
}

void RebaseModel::getAllTags(QString url, QJSValue callback)
{
    if (!url.contains(u"docker://"_s) || QStandardPaths::findExecutable(QStringLiteral("skopeo")).isEmpty()) {
        callback.call({1});
        return;
    }

    url = url.mid(url.indexOf(u"docker://"_s));

    QtConcurrent::run([url]() {
        QProcess proc;
        proc.start(u"skopeo"_s, {u"list-tags"_s, url});
        proc.waitForFinished();

        if (proc.exitCode() != 0)
            return QJsonArray();

        auto doc = QJsonDocument::fromJson(proc.readAllStandardOutput());

        auto result = doc.object().value(u"Tags"_s).toArray();

        for (auto it = result.begin(); it != result.end();) {
            if (it->toString().startsWith(u"sha256"_s)) {
                it = result.erase(it); // Erase returns the iterator to the next element
            } else {
                ++it;
            }
        }

        return result;
    }).then(this, [callback](QJsonArray result) {
        if (result.isEmpty())
            callback.call({1});
        else {
            QJsonDocument doc(result);
            QByteArray jsonString = doc.toJson(QJsonDocument::Compact);

            callback.call(QJSValueList({QString::fromUtf8(jsonString)}));
        }
    });
}
