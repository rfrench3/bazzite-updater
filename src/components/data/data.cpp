#include "data.h"
#include <qchar.h>
#include <qcontainerfwd.h>
#include <qjsonobject.h>
#include <qtconcurrentrun.h>
#include <qtmetamacros.h>

AppData::AppData(QObject *parent)
    : QObject(parent)
{
    reloadOstree();
    loadBestDrivers();
    loadOsRelease();
    loadStorageSpace();
};

StorageSpace StorageSpace::load()
{
    for (const QString &path : {u"/sysroot"_s, u"/var"_s}) {
        if (!QDir(path).exists())
            continue;

        QStorageInfo info(path);
        if (!info.isValid() || !info.isReady())
            continue;

        return StorageSpace{info.bytesTotal(), info.bytesTotal() - info.bytesFree()};
    }
    return {};
}

void AppData::loadStorageSpace()
{
    QtConcurrent::run([]() {
        return StorageSpace::load();
    }).then(this, [this](StorageSpace data) {
        storageSpace = data;
        Q_EMIT storageSpaceChanged();
    });
}

// (ex: u"bazzite-updater/config.ini"_s) Returns the full path to the config file that should be used.
QString findConfigFile(const QString &relativePath)
{
    QStringList bases;

    /* do NOT check the home config path. Any app with home folder access could
     * run arbitrary code in place of the normal system update. Only look for
     * configs in the standard places under /etc and /usr
     */

    // bases.append(qEnvironmentVariable("XDG_CONFIG_HOME", QDir::homePath() + u"/.config"_s));

    bases.append({u"/etc"_s, u"/usr/local/etc"_s, u"/usr/etc"_s});

    // append XDG_CONFIG_DIRS last because any user (or malicious program run by the user) can change it
    if (auto xdg_config = qEnvironmentVariable("XDG_CONFIG_DIRS"); xdg_config.isEmpty())
        bases.append(u"/etc/xdg"_s);
    else
        bases.append(xdg_config.split(u':', Qt::SkipEmptyParts));

    for (const QString &dir : bases) {
        const QString path = QDir(dir).filePath(relativePath);
        QFile file(path);

        if (file.exists()) {
            if (file.open(QIODevice::ReadOnly))
                return path;
            else
                qWarning() << "Config found at " << path << " but could not open: " << file.errorString();
        }
    }
    qWarning() << "App Config file not found: " << relativePath;
    return u""_s;
}

void AppData::loadBestDrivers()
{
    QtConcurrent::run([]() {
        return GpuDrivers::load();
    }).then(this, [this](GpuDrivers g) {
        this->gpu = std::move(g);
        Q_EMIT gpuChanged();
    });
}

GpuDrivers GpuDrivers::load()
{
    const auto path = u"/usr/libexec/bazzite-detect-nvidia-support-status"_s;

    if (!QFile::exists(path))
        return {};

    GpuDrivers result;

    QProcess proc;

    proc.start(path);
    if (!proc.waitForFinished(15000) || proc.exitStatus() != QProcess::NormalExit || proc.exitCode() != 0)
        return {};

    QString output = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();

    if (output == u"supported"_s)
        result.best = Gpu::Drivers::NVIDIA_OPEN;
    else if (output == u"legacy"_s)
        result.best = Gpu::Drivers::NVIDIA;
    else if (output == u"unsupported"_s)
        result.best = Gpu::Drivers::UNSUPPORTED;
    else if (output.isEmpty())
        result.best = Gpu::Drivers::BASE;
    else
        result.best = Gpu::Drivers::UNKNOWN;

    return result;
}

void AppData::reloadOstree(QJSValue callback)
{
    if (ostreeStatus.loading)
        return;

    ostreeStatus.loading = true;
    QtConcurrent::run([]() {
        return Ostree::load();
    })
        .then(this,
              [this, callback](Ostree os) {
                  if (os != Ostree()) {
                      this->ostree = std::move(os);
                      Q_EMIT ostreeChanged();
                      this->ostreeStatus.succeeded = true;
                  }
                  this->ostreeStatus.loading = false;
                  if (callback.isCallable())
                      callback.call();
              })
        .onCanceled(this, [this, callback]() {
            this->ostreeStatus.loading = false;
            if (callback.isCallable())
                callback.call();
        });
}

QJsonObject runJson(const QString &program, const QStringList &args)
{
    QProcess proc;
    proc.start(program, args);

    if (!proc.waitForStarted(5000)) {
        qWarning() << "Failed to start process:" << program << args << "| Error:" << proc.errorString();
        return {};
    }

    if (!proc.waitForFinished(15000)) {
        qWarning() << "Process timed out after 15s:" << program << args;
        proc.kill();
        return {};
    }

    if (proc.exitStatus() != QProcess::NormalExit || proc.exitCode() != 0) {
        const QString stdErr = QString::fromUtf8(proc.readAllStandardError()).trimmed();
        qWarning() << "Process exited with error:" << program << args << "| Exit status:" << proc.exitStatus() << "| Exit code:" << proc.exitCode()
                   << "| stderr:" << stdErr;
        return {};
    }

    return QJsonDocument::fromJson(proc.readAllStandardOutput()).object();
}

Ostree loadRpmOstree()
{
    Ostree result;
    const QJsonObject root = runJson(u"rpm-ostree"_s, {u"status"_s, u"--json"_s});

    for (const QJsonValue &v : root.value(u"deployments"_s).toArray()) {
        const QJsonObject d = v.toObject();
        OstreeDeployment dep;
        dep.isCurrent = d.value(u"booted"_s).toBool();
        dep.isStaged = d.value(u"staged"_s).toBool();
        for (const QJsonValue &p : d.value(u"requested-packages"_s).toArray())
            dep.layeredPackages << p.toString();
        for (const QJsonValue &p : d.value(u"requested-local-packages"_s).toArray())
            dep.layeredPackages << p.toString();
        result.deployments << dep;
    }
    return result;
}

Ostree loadBootc()
{
    Ostree result;

    // TODO: bootc status needs root
    //       Also review the aurora update script for handling this
    //       bootc has a compatibility value which can be used to determine if bootc or rpm-ostree should be used
    // https://github.com/get-aurora-dev/common/blob/f813004dd14804a674ea22f45dd538f0d4b56f08/system_files/shared/usr/share/ublue-os/just/update.just#L54
    //
    // also TODO: Recommend/enforce removing layered packages before a rebase
    const QJsonObject status = runJson(u"bootc"_s, {u"status"_s, u"--json"_s}).value(u"status"_s).toObject();

    // bootc reports up to three slots, each an object or null.
    // Same order as rpm-ostree: staged, booted, rollback.
    auto add = [&](const QString &key, bool current, bool staged) {
        if (!status.value(key).isObject())
            return;
        OstreeDeployment dep;
        dep.isCurrent = current;
        dep.isStaged = staged;
        result.deployments << dep;
    };
    add(u"staged"_s, false, true);
    add(u"booted"_s, true, false);
    add(u"rollback"_s, false, false);
    return result;
}

Ostree Ostree::load()
{
    if (!QStandardPaths::findExecutable(u"rpm-ostree"_s).isEmpty())
        return loadRpmOstree();
    if (!QStandardPaths::findExecutable(u"bootc"_s).isEmpty())
        return loadBootc();
    return {};
}

void AppData::loadOsRelease()
{
    if (osReleaseStatus.loading)
        return;

    osReleaseStatus.loading = true;
    QtConcurrent::run([this]() {
        QJsonObject data = {};
        auto file = QFile(u"/etc/os-release"_s);

        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            while (!file.atEnd()) {
                QByteArray arr = file.readLine();

                auto line = QString::fromUtf8(arr).trimmed();

                if (line.isEmpty() || line.startsWith(u'#'))
                    continue;

                int split = line.indexOf(u'=');
                if (split == -1)
                    continue;

                auto key = line.left(split);
                auto value = line.mid(split + 1);

                // Remove surrounding quotations, if there are any
                if (value.length() >= 2 && ((value.startsWith(u'"') && value.endsWith(u'"')) || (value.startsWith(u'\'') && value.endsWith(u'\'')))) {
                    value = value.sliced(1, value.length() - 2);
                }

                data.insert(key, value);
            }
        }

        loadAboutDataOs(data);

        return data;
    })
        .then(this,
              [this](QJsonObject data) {
                  if (data != QJsonObject()) {
                      this->osRelease = std::move(data);
                      Q_EMIT osReleaseChanged();
                      this->osReleaseStatus.succeeded = true;
                  }
                  this->osReleaseStatus.loading = false;
                  Q_EMIT aboutDataOsChanged();
              })
        .onCanceled(this, [this]() {
            this->osReleaseStatus.loading = false;
            Q_EMIT aboutDataOsChanged();
        });
}

void AppData::loadAboutDataOs(const QJsonObject &osRelease)
{
    aboutDataOsStatus.loading = true;

    QFile aboutData(findConfigFile(u"bazzite-updater/KAboutData_OS.json"_s));
    if (!aboutData.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open KAboutData_OS";
        aboutDataOs[u"displayName"_s] = u"Failed to fetch information."_s;
    } else {
        QByteArray file = aboutData.readAll();
        QJsonDocument doc = QJsonDocument::fromJson(file);
        aboutDataOs = doc.object();

        // Process specific values
        if (aboutDataOs[u"version"_s].toString() == u"@VERSION@"_s) {
            if (osRelease.contains(u"VERSION"_s))
                aboutDataOs.insert(u"version"_s, osRelease[u"VERSION"_s]);
            else if (osRelease.contains(u"VERSION_ID"_s))
                aboutDataOs.insert(u"version"_s, osRelease[u"VERSION_ID"_s]);
            else
                aboutDataOs.insert(u"version"_s, u"Unknown version"_s);
        }

        if (aboutDataOs[u"license"_s].toString() == u"@Apache-2.0@"_s) {
            // TODO: insert the entire apache 2.0 license
            aboutDataOs[u"license"_s] = u"https://www.apache.org/licenses/LICENSE-2.0.txt"_s;
        }

        // If the desired icon does not exist, allow QML to fallback to qrc:/fallbackIcon
        if (!QFile(aboutDataOs[u"programLogo"_s].toString()).exists())
            aboutDataOs[u"programLogo"_s] = u""_s;

        auto copyright = aboutDataOs[u"copyrightStatement"_s].toString();
        int idx = copyright.indexOf(u"@CURRENT_YEAR@"_s);
        if (idx != -1) {
            copyright.replace(idx, 14, QString::number(QDate::currentDate().year()));
            aboutDataOs.insert(u"copyrightStatement"_s, copyright);
        }

        aboutData.close();
        aboutDataOsStatus.succeeded = true;
    }

    aboutDataOsStatus.loading = false;
}
