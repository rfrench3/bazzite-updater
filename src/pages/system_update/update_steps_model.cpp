// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "update_steps_model.h"
#include <qcontainerfwd.h>
#include <qcoreapplication.h>
#include <qobject.h>
#include <qtmetamacros.h>

using namespace UpdateStepsNS;

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

    switch (static_cast<Roles>(role)) {
    case Roles::MODULE:
        return line.module;

    case Roles::PROGRESS_CURRENT:
        return line.progress_current;

    case Roles::PROGRESS_TOTAL:
        return line.progress_total;

    case Roles::EXIT_STATUS:
        return static_cast<int>(line.exit_status);

    default:
        return QVariant();
    }
}

QHash<int, QByteArray> Model::roleNames() const
{
    return {
        {Roles::MODULE, "module"},
        {Roles::PROGRESS_CURRENT, "progress_current"},
        {Roles::PROGRESS_TOTAL, "progress_total"},
        {Roles::EXIT_STATUS, "exit_status"},
    };
}

// TODO: Some way to update only specific entries like exit status without needing to re-specify progress_current/total is needed
void Model::updateData(const QString &module, int progress_current, int progress_total, ExitStatus exit_status, bool create_new)
{
    Line data{module, progress_current, progress_total, exit_status};

    auto it = std::find_if(m_lines.begin(), m_lines.end(), [&](const auto &line) {
        return line.module == module;
    });

    if (it != m_lines.end()) {
        *it = data;
        int i = std::distance(m_lines.begin(), it);
        Q_EMIT dataChanged(index(i, 0), index(i, 0));
        return;
    }
    if (create_new) {
        beginInsertRows(QModelIndex(), m_lines.size(), m_lines.size());
        m_lines.append(data);
        endInsertRows();
    }
}
