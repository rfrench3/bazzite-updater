// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "controllers.h"
#include <KLocalizedString>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QKeyEvent>

#define POLLING_RATE 16 // ~60FPS

ControllerManager::ControllerManager(QObject *parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
{
    SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");

    if (!SDL_Init(SDL_INIT_GAMEPAD)) {
        qWarning() << "SDL_Init Error:" << SDL_GetError();
        return;
    }

    connect(m_timer, &QTimer::timeout, this, QOverload<>::of(&ControllerManager::pollSDL));
    m_timer->start(POLLING_RATE);
    qDebug() << "ControllerManager initialized.";

    changeGamepadLabels(0);
}

void ControllerManager::setPollController(bool windowActiveState)
{
    if (windowActiveState == true) {
        // Window focused: Starting controller polling

        // Clear any events that occurred when unfocused,
        // except for controller connections/disconnections
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_GAMEPAD_ADDED)
                handleGamepadAdded(event.gdevice.which);
            else if (event.type == SDL_EVENT_GAMEPAD_REMOVED)
                handleGamepadRemoved(event.gdevice.which);
        }

        for (auto &[id, data] : m_gamepads) {
            data.leftStickVertical = 0;
            data.rightStickVertical = 0;
        }

        m_timer->start(POLLING_RATE);
    } else {
        // Window unfocused: Pausing controller polling
        m_timer->stop();

        for (auto &[id, data] : m_gamepads) {
            data.leftStickVertical = 0;
            data.rightStickVertical = 0;
        }
    }
}

void ControllerManager::pollSDL()
{
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        switch (event.type) {
        case SDL_EVENT_GAMEPAD_BUTTON_DOWN:
            Q_EMIT buttonPressed(event.gbutton.button);
            changeGamepadLabels(event.gbutton.which);
            break;

            // case SDL_EVENT_GAMEPAD_BUTTON_UP:
            //     break;

        case SDL_EVENT_GAMEPAD_AXIS_MOTION:
            handleAxisMotion(event);
            break;

        case SDL_EVENT_GAMEPAD_ADDED:
            handleGamepadAdded(event.gdevice.which);
            break;

        case SDL_EVENT_GAMEPAD_REMOVED:
            handleGamepadRemoved(event.gdevice.which);
            break;

            // default:
            //     qDebug() << "Other Event:" << event.type;
            //     break;
        }
    }
}

void ControllerManager::handleAxisMotion(SDL_Event &event)
{
    // Handle left stick vertical
    if (event.gaxis.axis == SDL_GAMEPAD_AXIS_LEFTY) {
        axisEmulateDpad(m_gamepads[event.gaxis.which].leftStickVertical, event.gaxis.value);
        m_gamepads[event.gaxis.which].leftStickVertical = event.gaxis.value;
    }

    // TODO: Handle right stick vertical
    else if (event.gaxis.axis == SDL_GAMEPAD_AXIS_RIGHTY)
        m_gamepads[event.gaxis.which].rightStickVertical = event.gaxis.value;

    changeGamepadLabels(event.gbutton.which);
}

void ControllerManager::axisEmulateDpad(const int16_t &axisPrev, const int16_t &axisNow)
{
    // If the state relative to the controller deadzone has changed, emulate the appropriate Dpad input

    // x < -DEADZONE
    if (axisNow < -DEADZONE && !(axisPrev < -DEADZONE))
        Q_EMIT buttonPressed(SDL_GAMEPAD_BUTTON_DPAD_UP);

    // x > DEADZONE
    else if (axisNow > DEADZONE && !(axisPrev > DEADZONE))
        Q_EMIT buttonPressed(SDL_GAMEPAD_BUTTON_DPAD_DOWN);
}

void ControllerManager::handleGamepadAdded(SDL_JoystickID which)
{
    if (m_gamepads.count(which) > 0) {
        qWarning() << "A gamepad was connected while already being connected!";
        return;
    }

    qDebug() << "New Device Detected! ID:" << which;

    SDL_Gamepad *newGamepad = SDL_OpenGamepad(which);

    if (newGamepad) {
        m_gamepads[which].gamepad = newGamepad;

        qDebug() << "Gamepad Opened Name:" << SDL_GetGamepadName(newGamepad);
        changeGamepadLabels(which);
    } else {
        qWarning() << "Could not open gamepad!" << SDL_GetError();
    }
}

void ControllerManager::handleGamepadRemoved(SDL_JoystickID which)
{
    auto find_gamepad = m_gamepads.find(which);

    if (find_gamepad != m_gamepads.end()) {
        if (find_gamepad->second.gamepad) {
            qDebug() << "Device Removed ID:" << which;
            SDL_CloseGamepad(find_gamepad->second.gamepad);
        }
        m_gamepads.erase(find_gamepad);
    }
    changeGamepadLabels(0);
}

void ControllerManager::changeGamepadLabels(SDL_JoystickID which)
{
    // Only change labels when necessary
    if (which == m_focusedJoystick)
        return;

    m_focusedJoystick = which;

    if (which) {
        SDL_Gamepad *temp = m_gamepads[which].gamepad;
        m_labels.m_a = getLabelForButton(temp, SDL_GAMEPAD_BUTTON_SOUTH);
        m_labels.m_b = getLabelForButton(temp, SDL_GAMEPAD_BUTTON_EAST);
        m_labels.m_x = getLabelForButton(temp, SDL_GAMEPAD_BUTTON_WEST);
        m_labels.m_y = getLabelForButton(temp, SDL_GAMEPAD_BUTTON_NORTH);
        m_labels.m_S = QStringLiteral(" ");
        m_labels.m_S_big = m_labels.m_S + m_labels.m_S + m_labels.m_S;
    } else {
        m_labels.m_a = QStringLiteral("");
        m_labels.m_b = QStringLiteral("");
        m_labels.m_x = QStringLiteral("");
        m_labels.m_y = QStringLiteral("");
        m_labels.m_S = QStringLiteral("");
        m_labels.m_S_big = QStringLiteral("");
    }

    Q_EMIT labelsChanged();
}

QString ControllerManager::getLabelForButton(SDL_Gamepad *gamepad, SDL_GamepadButton button)
{
    // Ask SDL what is written on this physical button
    SDL_GamepadButtonLabel label = SDL_GetGamepadButtonLabel(gamepad, button);

    switch (label) {
    case SDL_GAMEPAD_BUTTON_LABEL_A:
        return QStringLiteral("(A)");
    case SDL_GAMEPAD_BUTTON_LABEL_B:
        return QStringLiteral("(B)");
    case SDL_GAMEPAD_BUTTON_LABEL_X:
        return QStringLiteral("(X)");
    case SDL_GAMEPAD_BUTTON_LABEL_Y:
        return QStringLiteral("(Y)");
    case SDL_GAMEPAD_BUTTON_LABEL_CROSS:
        return i18n("(Cross)");
    case SDL_GAMEPAD_BUTTON_LABEL_CIRCLE:
        return i18n("(Circle)");
    case SDL_GAMEPAD_BUTTON_LABEL_SQUARE:
        return i18n("(Square)");
    case SDL_GAMEPAD_BUTTON_LABEL_TRIANGLE:
        return i18n("(Triangle)");
    default:
        return QStringLiteral("(?)"); // Unknown
    }
}
