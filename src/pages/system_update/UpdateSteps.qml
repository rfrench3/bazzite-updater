// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import io.github.rfrench3.bazzite_updater

ColumnLayout {
    id: root

    Repeater {
        model: SystemUpdateBackend.updateStepsModel

        delegate: RowLayout {
            id: del
            required property string module
            required property int progress_current
            required property int progress_total
            required property int exit_status

            spacing: Kirigami.Units.gridUnit

            Label {
                text: del.module
            }

            ProgressBar {
                Layout.fillWidth: true
                indeterminate: del.progress_current === -1
                value: del.progress_current
                to: del.progress_total
            }

            Loader {
                sourceComponent: {
                    if (del.exit_status === 0)
                        return busyComponent;
                    if (del.exit_status === 1)
                        return checkmarkComponent;
                    return errorComponent;
                }

                Component {
                    id: busyComponent
                    BusyIndicator {
                        id: busyIndicator
                    }
                }

                Component {
                    id: checkmarkComponent
                    Kirigami.Icon {
                        source: "checkmark-symbolic"
                    }
                }

                Component {
                    id: errorComponent
                    Kirigami.Icon {
                        source: "error-symbolic"
                    }
                }
            }

            // Smooth fade-in animation
            opacity: 0
            Component.onCompleted: {
                opacity = 1;
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
