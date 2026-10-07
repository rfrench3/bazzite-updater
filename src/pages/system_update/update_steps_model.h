// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QAbstractListModel>
#include <QApplication>
#include <QClipboard>
#include <QtCore>

#include <qcontainerfwd.h>
#include <qhash.h>
#include <qnamespace.h>
#include <qqmlintegration.h>
#include <qtmetamacros.h>

namespace UpdateStepsNS
{
Q_NAMESPACE;
QML_ELEMENT

enum Roles {
    MODULE = Qt::UserRole + 1,
    PROGRESS_CURRENT,
    PROGRESS_TOTAL,
    EXIT_STATUS
};
Q_ENUM_NS(Roles)

enum ExitStatus {
    RUNNING,
    SUCCESS,
    ERROR
};
Q_ENUM_NS(ExitStatus)

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

    QHash<int, QByteArray> roleNames() const override;

    void updateData(const QString &module, int progress_current, int progress_total, ExitStatus exit_status, bool create_new = true);

    QStringList modulesList() const;

private:
    struct Line {
        QString module;
        int progress_current;
        int progress_total;
        ExitStatus exit_status;
    };

    QVector<Line> m_lines;
};
};
