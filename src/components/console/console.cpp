// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "console.h"

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