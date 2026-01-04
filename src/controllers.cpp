// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
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
    qDebug() << "ControllerManager initialized. Waiting for input...";

    changeGamepadLabels();
}

void ControllerManager::setPollController(bool windowActiveState)
{
    if (windowActiveState == true) {
        qDebug() << "Window focused: Starting controller polling.";

        // Clear any events that occurred when unfocused,
        // except for controller connections/disconnections
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_GAMEPAD_ADDED)
                handleGamepadAdded(event.gdevice.which);
            else if (event.type == SDL_EVENT_GAMEPAD_REMOVED)
                handleGamepadRemoved(event.gdevice.which);
        }

        m_lStickUpActive = false;
        m_lStickDownActive = false;
        m_rStickVertical = 0;

        m_timer->start(POLLING_RATE);
    } else {
        qDebug() << "Window unfocused: Pausing controller polling.";
        m_timer->stop();

        m_lStickUpActive = false;
        m_lStickDownActive = false;
        m_rStickVertical = 0;
    }
}

void ControllerManager::pollSDL()
{
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        switch (event.type) {
        case SDL_EVENT_GAMEPAD_BUTTON_DOWN:
            qDebug() << "BUTTON DOWN: " << event.gbutton.button;
            Q_EMIT buttonPressed(event.gbutton.button);
            break;

        case SDL_EVENT_GAMEPAD_BUTTON_UP:
            qDebug() << "BUTTON UP: " << event.gbutton.button;
            break;

        case SDL_EVENT_GAMEPAD_AXIS_MOTION:
            qDebug() << "AXIS MOTION";

            // Handle left stick vertical
            if (event.gaxis.axis == SDL_GAMEPAD_AXIS_LEFTY) {
                int16_t value = event.gaxis.value;

                // --- HANDLE UP (Negative Value) ---
                if (value < -DEADZONE) {
                    if (!m_lStickUpActive) {
                        m_lStickUpActive = true;
                        // Pretend the user pressed D-Pad Up (ID 11)
                        Q_EMIT buttonPressed(SDL_GAMEPAD_BUTTON_DPAD_UP);
                    }
                }
                // Reset if the stick returns to center (or goes down)
                else if (value > -DEADZONE && m_lStickUpActive) {
                    m_lStickUpActive = false;
                    // Q_EMIT buttonReleased(SDL_GAMEPAD_BUTTON_DPAD_UP);
                }

                // --- HANDLE DOWN (Positive Value) ---
                if (value > DEADZONE) {
                    if (!m_lStickDownActive) {
                        m_lStickDownActive = true;
                        // Pretend the user pressed D-Pad Down (ID 12)
                        Q_EMIT buttonPressed(SDL_GAMEPAD_BUTTON_DPAD_DOWN);
                    }
                }
                // Reset if the stick returns to center (or goes up)
                else if (value < DEADZONE && m_lStickDownActive) {
                    m_lStickDownActive = false;
                    // Q_EMIT buttonReleased(SDL_GAMEPAD_BUTTON_DPAD_DOWN);
                }
            }
            // handle right stick vertical
            else if (event.gaxis.axis == SDL_GAMEPAD_AXIS_RIGHTY) {
                m_rStickVertical = event.gaxis.value;
            }
            break;

        case SDL_EVENT_GAMEPAD_ADDED:
            handleGamepadAdded(event.gdevice.which);
            break;

        case SDL_EVENT_GAMEPAD_REMOVED:
            handleGamepadRemoved(event.gdevice.which);
            break;

        default:
            qDebug() << "Other Event:" << event.type;
            break;
        }
    }
}

void ControllerManager::handleGamepadAdded(SDL_JoystickID which)
{
    qDebug() << "New Device Detected! ID:" << which;

    if (m_gamepad) {
        SDL_CloseGamepad(m_gamepad);
        m_gamepad = nullptr;
    }

    m_gamepad = SDL_OpenGamepad(which);

    if (m_gamepad) {
        qDebug() << "Gamepad Opened Name:" << SDL_GetGamepadName(m_gamepad);
        m_gamepadPresent = true;
        changeGamepadLabels();
    } else {
        qWarning() << "Could not open gamepad!";
    }
}

void ControllerManager::handleGamepadRemoved(SDL_JoystickID which)
{
    qDebug() << "Device Removed ID:" << which;
    if (m_gamepad) {
        SDL_CloseGamepad(m_gamepad);
        m_gamepad = nullptr;
    }
    changeGamepadLabels();
}

void ControllerManager::changeGamepadLabels()
{
    if (m_gamepad) {
        m_labels.m_a = getLabelForButton(m_gamepad, SDL_GAMEPAD_BUTTON_SOUTH);
        m_labels.m_b = getLabelForButton(m_gamepad, SDL_GAMEPAD_BUTTON_EAST);
        m_labels.m_x = getLabelForButton(m_gamepad, SDL_GAMEPAD_BUTTON_WEST);
        m_labels.m_y = getLabelForButton(m_gamepad, SDL_GAMEPAD_BUTTON_NORTH);
        m_labels.m_S = QStringLiteral(" ");
    } else {
        m_labels.m_a = QStringLiteral("");
        m_labels.m_b = QStringLiteral("");
        m_labels.m_x = QStringLiteral("");
        m_labels.m_y = QStringLiteral("");
        m_labels.m_S = QStringLiteral("");
    }

    Q_EMIT gamepadPresentChanged();
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
