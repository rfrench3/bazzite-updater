// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QAbstractListModel>
#include <QtCore>
#include <qqmlintegration.h>

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
};

}
