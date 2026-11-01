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

static void applyFinalState(Model::Line &l)
{
    if (l.exit_status == SUCCESS) {
        l.progress_current = 2;
        l.progress_total = 2;
    } else if (l.exit_status == ERROR) {
        l.progress_current = 0;
        l.progress_total = 2;
    }
}

void Model::updateData(const QString &module, int progress_current, int progress_total, ExitStatus exit_status, bool create_new)
{
    auto it = std::find_if(m_lines.begin(), m_lines.end(), [&](const Line &line) {
        return line.module == module;
    });

    if (it != m_lines.end()) {
        // Once a module has an exit status (SUCCESS or ERROR) it is frozen.
        if (it->exit_status != RUNNING)
            return;

        Line data = *it;
        if (progress_current != ProgressNoChange)
            data.progress_current = progress_current;
        if (progress_total != ProgressNoChange)
            data.progress_total = progress_total;
        if (exit_status != NO_CHANGE)
            data.exit_status = exit_status;
        applyFinalState(data);

        *it = data;
        const int i = std::distance(m_lines.begin(), it);
        Q_EMIT dataChanged(index(i, 0), index(i, 0));
        return;
    }

    if (!create_new || module.isEmpty())
        return;

    Line data{module,
              progress_current == ProgressNoChange ? ProgressIndeterminate : progress_current,
              progress_total == ProgressNoChange ? 2 : progress_total,
              exit_status == NO_CHANGE ? RUNNING : exit_status};
    applyFinalState(data);

    beginInsertRows(QModelIndex(), m_lines.size(), m_lines.size());
    m_lines.append(data);
    endInsertRows();
}

void Model::clearData()
{
    beginResetModel();
    m_lines.clear();
    endResetModel();
}

QStringList Model::modules() const
{
    QStringList result;
    result.reserve(m_lines.size());
    for (const Line &line : m_lines)
        result.append(line.module);
    return result;
}

void Model::setAllRunningExitStatus(ExitStatus exit_status)
{
    for (int i = 0; i < m_lines.size(); ++i) {
        if (m_lines.at(i).exit_status == RUNNING)
            updateData(m_lines.at(i).module, ProgressNoChange, ProgressNoChange, exit_status, false);
    }
}
