// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QTimer>
#include <SDL3/SDL.h>
#include <cstdint>
#include <map>

struct ControllerLabels {
    Q_GADGET
    // Expose members as properties to QML
    Q_PROPERTY(QString a MEMBER m_a CONSTANT)
    Q_PROPERTY(QString b MEMBER m_b CONSTANT)
    Q_PROPERTY(QString x MEMBER m_x CONSTANT)
    Q_PROPERTY(QString y MEMBER m_y CONSTANT)
    Q_PROPERTY(QString space MEMBER m_S CONSTANT)
    Q_PROPERTY(QString space_large MEMBER m_S_big CONSTANT)

public:
    // The correct glyphs are initialized by ControllerManager::changeGamepadLabels()
    // The a-b-x-y names here follow the Xbox layout
    QString m_a;
    QString m_b;
    QString m_x;
    QString m_y;
    QString m_S;
    QString m_S_big; // m_S times three
};

// 2. Register it for QVariant (Required for Q_GADGET)
Q_DECLARE_METATYPE(ControllerLabels)

class ControllerManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(ControllerLabels labels READ labels NOTIFY labelsChanged)
    // Q_PROPERTY(bool gamepadPresent READ gamepadPresent NOTIFY gamepadPresentChanged)

    struct GamepadData {
        SDL_Gamepad *gamepad = nullptr;

        // left stick emulates d-pad inputs,
        // range is [x < -DEADZONE, |x| < DEADZONE, x > DEADZONE ]
        int16_t leftStickVertical = 0;

        // TODO: emulates scrolling for scrollable areas
        int16_t rightStickVertical = 0;
    };

    // bool m_gamepadPresent = false;
    void pollSDL();
    QTimer *m_timer;

    // m_focusedJoystick ensures the glyphs don't re-update on every input from one controller
    SDL_JoystickID m_focusedJoystick = 0;
    std::map<SDL_JoystickID, GamepadData> m_gamepads;

    void changeGamepadLabels(SDL_JoystickID which);
    QString getLabelForButton(SDL_Gamepad *gamepad, SDL_GamepadButton button);
    void handleGamepadAdded(SDL_JoystickID which);
    void handleGamepadRemoved(SDL_JoystickID which);
    void handleAxisMotion(SDL_Event &event);
    void axisEmulateDpad(const int16_t &axisPrev, const int16_t &axisNow);

    ControllerLabels m_labels;

    const int16_t DEADZONE = 12000; // Range: -32768,32768

public:
    ControllerManager(QObject *parent = nullptr);

    ControllerLabels labels() const
    {
        return m_labels;
    }

    Q_INVOKABLE void setPollController(bool windowActiveState);
    Q_SIGNAL void buttonPressed(uint8_t button);
    Q_SIGNAL void gamepadPresentChanged();
    Q_SIGNAL void labelsChanged();
};
