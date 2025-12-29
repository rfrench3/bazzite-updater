// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QTimer>
#include <SDL3/SDL.h>

struct ControllerLabels {
    Q_GADGET
    // Expose members as properties to QML
    Q_PROPERTY(QString a MEMBER m_a CONSTANT)
    Q_PROPERTY(QString b MEMBER m_b CONSTANT)
    Q_PROPERTY(QString x MEMBER m_x CONSTANT)
    Q_PROPERTY(QString y MEMBER m_y CONSTANT)
    Q_PROPERTY(QString space MEMBER m_S CONSTANT)

public:
    // The correct glyphs are initialized by ControllerManager::changeGamepadLabels()
    // The a-b-x-y names here follow the Xbox layout
    QString m_a;
    QString m_b;
    QString m_x;
    QString m_y;
    QString m_S;
};

// 2. Register it for QVariant (Required for Q_GADGET)
Q_DECLARE_METATYPE(ControllerLabels)

class ControllerManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(ControllerLabels labels READ labels NOTIFY labelsChanged)
    Q_PROPERTY(bool gamepadPresent READ gamepadPresent NOTIFY gamepadPresentChanged)

    bool m_gamepadPresent = false;
    void pollSDL();
    QTimer *m_timer;
    SDL_Gamepad *m_gamepad = nullptr;
    void changeGamepadLabels();
    QString getLabelForButton(SDL_Gamepad *gamepad, SDL_GamepadButton button);
    void handleGamepadAdded(SDL_JoystickID which);
    void handleGamepadRemoved(SDL_JoystickID which);
    void resetInputState();

    ControllerLabels m_labels;

    const int16_t DEADZONE = 12000; // Range: -32768,32768

    // left stick controls menu navigation
    bool m_lStickUpActive = false;
    bool m_lStickDownActive = false;

    // right stick controls scrolling (e.g. updater screen console)
    // TODO: implement this
    int16_t m_rStickVertical = 0;

public:
    ControllerManager(QObject *parent = nullptr);

    bool gamepadPresent() const
    {
        return m_gamepadPresent;
    }
    ControllerLabels labels() const
    {
        return m_labels;
    }

    Q_INVOKABLE void setPollController(bool windowActiveState);
    Q_SIGNAL void buttonPressed(uint8_t button);
    Q_SIGNAL void gamepadPresentChanged();
    Q_SIGNAL void labelsChanged();
};
