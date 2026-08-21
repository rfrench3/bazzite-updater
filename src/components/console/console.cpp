// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "console.h"
#include "utils.h"
#include <qcontainerfwd.h>
#include <qobject.h>
#include <qprocess.h>

using namespace Console;

int Model::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    else
        return m_lines.size();
}

QVariant Model::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_lines.size())
        return QVariant();

    const Line &line = m_lines.at(index.row());

    switch (role) {
    case Qt::DisplayRole:
        return line.content;

    case Qt::DecorationRole:
        return QVariant::fromValue(line.level);

    default:
        return QVariant();
    }
}

void Model::newLine(const QString &content, LogLevel level)
{
    const int row = m_lines.size();
    beginInsertRows(QModelIndex(), row, row);
    m_lines.append({content, level});
    endInsertRows();
}

void Model::copyToClipboard() const
{
    QString plainText;

    for (int row = 0; row < rowCount(); ++row) {
        plainText += data(index(row, 0), Qt::DisplayRole).toString() + QStringLiteral("\n");
    }

    if (!plainText.isEmpty())
        QApplication::clipboard()->setText(plainText);
}

void Model::runProcess(QStringList process,
                       function<void(int)> onFinish,
                       function<void(QProcess::ProcessError)> onError,
                       function<void(QString, LogLevel)> lineFormatter)
{
    QProcess *command = new QProcess(this);

    // Default to just printing a new line, while allowing more advanced custom logic
    auto lineHandler = (lineFormatter) ? lineFormatter : [=, this](QString content, LogLevel level) {
        newLine(content, level);
    };

    auto makeLogger = [=](Console::LogLevel level, QProcess::ProcessChannel channel) {
        return [=]() {
            command->setReadChannel(channel);
            while (command->canReadLine()) {
                const QByteArray line = command->readLine();

                if (line.isEmpty())
                    continue;

                lineHandler(QString::fromUtf8(line), level);
            }
        };
    };

    auto loggerInfo = makeLogger(Console::LogLevel::Info, QProcess::ProcessChannel::StandardOutput);
    auto loggerError = makeLogger(Console::LogLevel::Error, QProcess::ProcessChannel::StandardError);

    connect(command, &QProcess::readyReadStandardOutput, this, loggerInfo);
    connect(command, &QProcess::readyReadStandardError, this, loggerError);

    connect(command, &QProcess::finished, this, [=, this](int exitCode, QProcess::ExitStatus exitStatus) {
        newLine(u"Command finished with exit code %1 and exit status %2"_s.arg(exitCode).arg(exitStatus), Console::LogLevel::Info);
        onFinish(exitCode);
        command->deleteLater();
    });

    connect(command, &QProcess::errorOccurred, this, [=, this](QProcess::ProcessError error) {
        newLine(u"Command failed with error code: %1"_s.arg(error), Console::LogLevel::Error);
        onError(error);
        command->deleteLater();
    });

    // FIXME: A command waiting for user input will stall the process forever

    QStringList display;
    display << u">"_s << process;
    newLine(display.join(u' '), LogLevel::Info);

    Utils::startProcess(command, {u"/usr/bin/sh"_s, u"-c"_s, process.join(u' ')});
}
