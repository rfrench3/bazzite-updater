// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QObject>
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

class Entry : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString content MEMBER m_content CONSTANT)
    Q_PROPERTY(LogLevel level MEMBER m_level CONSTANT)
public:
    Entry(const QString &content, LogLevel level)
        : m_content(content)
        , m_level(level)
    {
    }

    QString m_content;
    LogLevel m_level;
};

class Model : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QObjectList lines MEMBER lines NOTIFY linesChanged)
public:
    QObjectList lines;

    Q_INVOKABLE void newLine(QString content, LogLevel level);

    Q_SIGNAL void linesChanged();
};

}
