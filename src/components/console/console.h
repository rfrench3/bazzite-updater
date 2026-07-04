// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include "utils.h"
#include <QAbstractListModel>
#include <QApplication>
#include <QClipboard>
#include <QtCore>
#include <functional>
#include <qqmlintegration.h>

using std::function;

namespace Console
{
Q_NAMESPACE
QML_ELEMENT

enum class LogLevel {
    Info,
    Warn,
    Error,
    Debug,
    ErrorCritical
};
Q_ENUM_NS(LogLevel)

class Model : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit Model(QObject *parent = nullptr)
        : QAbstractListModel(parent)
    {
    }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    void newLine(const QString &content, LogLevel level);

private:
    struct Line {
        QString content;
        LogLevel level;
    };

    QVector<Line> m_lines;

public:
    Q_INVOKABLE void copyToClipboard() const;

    // Runs the defined process until completion. Does not use custom LogLevel logic.
    // onFinish and onError can be provided to run custom logic upon QProcess::finished and QProcess::errorOccurred.
    // customFormatter can be used to edit/reject lines of text before they are sent to the view.
    void runProcess(Utils::CommandData data,
                    function<void(int)> onFinish = nullptr,
                    function<void(QProcess::ProcessError)> onError = nullptr,
                    function<void(QString, LogLevel)> customFormatter = nullptr);
};

}
