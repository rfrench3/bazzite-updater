/*
 *  SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include <KLocalizedString>
#include <QApplication>
#include <QClipboard>
#include <QEventLoop>
#include <QFile>
#include <QJSEngine>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSignalSpy>
#include <QTest>
#include <QTextStream>
#include <QTimer>

#include "system_update.h"
#include "utils.h"

using namespace Qt::Literals::StringLiterals;

class TestSystemUpdate : public QObject
{
    Q_OBJECT

private:
    SystemUpdate *m_systemUpdate = nullptr;
    AppState *m_appState = nullptr;
    QJSEngine *m_jsEngine = nullptr;

private Q_SLOTS:
    void initTestCase()
    {
        // Initialize KI18n for translation strings
        KLocalizedString::setApplicationDomain("bazzite_updater");

        // Create QApplication if not already created (needed for clipboard tests)
        if (!qApp) {
            int argc = 0;
            char **argv = nullptr;
            new QApplication(argc, argv);
        }
    }

    void init()
    {
        // Create fresh instances for each test
        m_appState = new AppState();
        m_systemUpdate = new SystemUpdate(this);
        m_systemUpdate->setAppState(m_appState);
        m_systemUpdate->setPlaceholderColor(u"#888888"_s);

        // Create JS engine for callback tests
        m_jsEngine = new QJSEngine(this);
    }

    void cleanup()
    {
        // Clean up after each test
        delete m_systemUpdate;
        delete m_appState;
        delete m_jsEngine;
        m_systemUpdate = nullptr;
        m_appState = nullptr;
        m_jsEngine = nullptr;
    }

    void cleanupTestCase()
    {
        // Final cleanup
    }

    // Test basic property getters/setters
    void testPropertyGettersSetters()
    {
        // Test initial values
        QCOMPARE(m_systemUpdate->consoleText(), u""_s);
        QCOMPARE(m_systemUpdate->progressLevel(), 0);
        QCOMPARE(m_systemUpdate->blockUpdate(), false);

        // Test setters with signal spies
        QSignalSpy consoleTextSpy(m_systemUpdate, &SystemUpdate::consoleTextChanged);
        QSignalSpy statusTextSpy(m_systemUpdate, &SystemUpdate::statusTextChanged);
        QSignalSpy progressLevelSpy(m_systemUpdate, &SystemUpdate::progressLevelChanged);
        QSignalSpy blockUpdateSpy(m_systemUpdate, &SystemUpdate::blockUpdateChanged);

        // Test appendConsoleText
        m_systemUpdate->appendConsoleText(u"Test message"_s, SystemUpdate::LogLevel::INFO);
        QVERIFY(m_systemUpdate->consoleText().contains(u"Test message"_s));
        QCOMPARE(consoleTextSpy.count(), 1);

        // Test setStatusText
        m_systemUpdate->setStatusText(u"Running"_s);
        QCOMPARE(m_systemUpdate->statusText(), u"Running"_s);
        QCOMPARE(statusTextSpy.count(), 1);

        // Test setProgressLevel
        m_systemUpdate->setProgressLevel(50);
        QCOMPARE(m_systemUpdate->progressLevel(), 50);
        QCOMPARE(progressLevelSpy.count(), 1);

        // Test setBlockUpdate
        m_systemUpdate->setBlockUpdate(true);
        QCOMPARE(m_systemUpdate->blockUpdate(), true);
        QCOMPARE(blockUpdateSpy.count(), 1);
    }

    // Test console text formatting with different log levels
    void testConsoleTextFormatting()
    {
        // Test INFO level (normal text)
        m_systemUpdate->appendConsoleText(u"Info message"_s, SystemUpdate::LogLevel::INFO);
        QString console = m_systemUpdate->consoleText();
        QVERIFY(console.contains(u"Info message"_s));
        QVERIFY(!console.contains(u"<b>"_s)); // Not bold

        // Test DEBUG level (should be in placeholder color)
        m_systemUpdate->appendConsoleText(u"Debug message"_s, SystemUpdate::LogLevel::DEBUG);
        console = m_systemUpdate->consoleText();
        QVERIFY(console.contains(u"debug: Debug message"_s));

        // Test WARN level (should be bold)
        m_systemUpdate->appendConsoleText(u"Warning message"_s, SystemUpdate::LogLevel::WARN);
        console = m_systemUpdate->consoleText();
        QVERIFY(console.contains(u"WARNING: Warning message"_s));
        QVERIFY(console.contains(u"<b>"_s)); // Bold

        // Test ERROR level (should be bold)
        m_systemUpdate->appendConsoleText(u"Error message"_s, SystemUpdate::LogLevel::ERROR);
        console = m_systemUpdate->consoleText();
        QVERIFY(console.contains(u"ERROR: Error message"_s));
        QVERIFY(console.contains(u"<b>"_s)); // Bold

        // Test ERROR_CRITICAL level (should be bold)
        m_systemUpdate->appendConsoleText(u"Critical error"_s, SystemUpdate::LogLevel::ERROR_CRITICAL);
        console = m_systemUpdate->consoleText();
        QVERIFY(console.contains(u"CRITICAL ERROR: Critical error"_s));
        QVERIFY(console.contains(u"<b>"_s)); // Bold

        // Verify line breaks are present
        QVERIFY(console.contains(u"<br>"_s));
    }

    // Test clipboard copy functionality
    void testCopyToClipboard()
    {
        QString htmlText = u"<b>Bold text</b><br>Line 2<br><font color='red'>Colored</font>"_s;
        m_systemUpdate->copyToClipboard(htmlText);

        QString clipboardText = QApplication::clipboard()->text();

        // Should strip HTML tags and convert <br> to newlines
        QVERIFY(!clipboardText.contains(u"<b>"_s));
        QVERIFY(!clipboardText.contains(u"</b>"_s));
        QVERIFY(!clipboardText.contains(u"<br>"_s));
        QVERIFY(!clipboardText.contains(u"<font"_s));
        QVERIFY(clipboardText.contains(u"Bold text"_s));
        QVERIFY(clipboardText.contains(u"\n"_s)); // Newlines
        QVERIFY(clipboardText.contains(u"Colored"_s));
    }

    // Test AppState integration
    void testAppStateIntegration()
    {
        QVERIFY(m_appState != nullptr);

        // Initially not running
        QCOMPARE(m_appState->updateRunning(), false);
        QCOMPARE(m_appState->commandSucceeded(), false);

        QSignalSpy updateRunningSpy(m_appState, &AppState::updateRunningChanged);
        QSignalSpy commandSucceededSpy(m_appState, &AppState::commandSucceededChanged);

        // Test setUpdateRunning
        m_appState->setUpdateRunning(true);
        QCOMPARE(m_appState->updateRunning(), true);
        QCOMPARE(updateRunningSpy.count(), 1);

        // An update is running
        QCOMPARE(m_appState->commandRunning(), true);
        QCOMPARE(m_appState->allowCommands(), false);

        m_appState->setUpdateRunning(false);

        // Nothing should block commands
        QCOMPARE(m_appState->commandRunning(), false);
        QCOMPARE(m_appState->allowCommands(), true);

        // Test setCommandSucceeded
        m_appState->setCommandSucceeded(true);
        QCOMPARE(m_appState->commandSucceeded(), true);
        QCOMPARE(commandSucceededSpy.count(), 1);

        // CommandSucceeded is true
        QCOMPARE(m_appState->allowCommands(), false);
    }

    // Test runUpdate with missing service
    void testRunUpdateMissingService()
    {
        // This test verifies that runUpdate properly handles missing uupd-manual.service
        // Since we're doing minimal mocking, we'll test the callback behavior

        // Only run if service is not actually present (otherwise skip this test)
        if (!Utils::isServicePresent(u"uupd-manual.service"_s)) {
            // Create a lambda-based callback
            auto callback = m_jsEngine->evaluate(QStringLiteral("(function(exitCode) { })"));

            // Since we can't easily capture C++ state from JS, let's check the signals instead
            QSignalSpy blockUpdateSpy(m_systemUpdate, &SystemUpdate::blockUpdateChanged);

            m_systemUpdate->runUpdate(callback);

            // Should set blockUpdate to true and show error
            QCOMPARE(m_systemUpdate->blockUpdate(), true);
            QVERIFY(blockUpdateSpy.count() > 0);
            QVERIFY(m_systemUpdate->consoleText().contains(u"CRITICAL ERROR"_s));
            QVERIFY(m_systemUpdate->statusText().contains(u"ERROR"_s));
        } else {
            QSKIP("uupd-manual.service is present, skipping missing service test");
        }
    }

    // Test QJSValue callback mechanism
    void testJSCallbackMechanism()
    {
        // Test that we can create and call JS callbacks properly
        // Use a simpler approach that doesn't rely on globalThis behavior
        auto callback = m_jsEngine->evaluate(QStringLiteral("(function(code, result) { return code + ':' + result; })"));

        QVERIFY(callback.isCallable());

        // Call the callback and check return value
        QJSValue result = callback.call({0, u"success"_s});
        QCOMPARE(result.toString(), u"0:success"_s);
    }

    // Test error callback with JSON payload
    void testErrorCallbackJSON()
    {
        // Test JSON construction that would be passed to error callback
        QJsonObject errorDetails;
        errorDetails[u"System_Update"_s] = true;
        errorDetails[u"Brew_Update"_s] = false;
        errorDetails[u"System_Apps"_s] = false;
        errorDetails[u"Apps_for_User"_s] = false;
        errorDetails[u"Distroboxes_for_User"_s] = false;
        errorDetails[u"Unknown_Error"_s] = false;

        QJsonDocument errorDoc(errorDetails);
        QString errorJson = QString::fromUtf8(errorDoc.toJson(QJsonDocument::Compact));

        // Verify JSON was created
        QVERIFY(!errorJson.isEmpty());

        // Parse and verify structure
        QJsonDocument receivedDoc = QJsonDocument::fromJson(errorJson.toUtf8());
        QVERIFY(receivedDoc.isObject());
        QJsonObject receivedObj = receivedDoc.object();
        QCOMPARE(receivedObj[u"System_Update"_s].toBool(), true);
        QCOMPARE(receivedObj[u"Brew_Update"_s].toBool(), false);
    }

    // Test Utils static methods
    void testUtilsStaticMethods()
    {
        bool isFlatpak = Utils::isFlatpak();
        QVERIFY(isFlatpak == false);

        // Test isServicePresent
        // This is an integration test - it actually checks systemctl
        bool serviceExists = Utils::isServicePresent(u"systemd-journald.service"_s);
        QVERIFY(serviceExists == true);

        bool lsExists = Utils::isProgramPresent(u"ls"_s);
        QVERIFY(lsExists == true);

        bool fakeProgram = Utils::isProgramPresent(u"this_program_definitely_does_not_exist_12345"_s);
        QCOMPARE(fakeProgram, false);
    }

    // Test that systemUpdate properly sets placeholder color
    void testPlaceholderColorSetting()
    {
        m_systemUpdate->setPlaceholderColor(u"#FF0000"_s);

        // Add a DEBUG message and verify it uses the color
        m_systemUpdate->appendConsoleText(u"Colored debug"_s, SystemUpdate::LogLevel::DEBUG);
        QString console = m_systemUpdate->consoleText();

        QVERIFY(console.contains(u"#FF0000"_s));
        QVERIFY(console.contains(u"Colored debug"_s));
    }

    // Test multiple console appends maintain line breaks
    void testMultipleConsoleAppends()
    {
        m_systemUpdate->appendConsoleText(u"Line 1"_s, SystemUpdate::LogLevel::INFO);
        m_systemUpdate->appendConsoleText(u"Line 2"_s, SystemUpdate::LogLevel::INFO);
        m_systemUpdate->appendConsoleText(u"Line 3"_s, SystemUpdate::LogLevel::INFO);

        QString console = m_systemUpdate->consoleText();

        // Should have line breaks between messages
        QVERIFY(console.contains(u"Line 1"_s));
        QVERIFY(console.contains(u"Line 2"_s));
        QVERIFY(console.contains(u"Line 3"_s));

        // Count <br> tags (should be at least 2 for 3 lines)
        int brCount = console.count(u"<br>"_s);
        QVERIFY(brCount >= 2);
    }

    // Test getServiceState and getServiceResult methods
    void testServiceStateMethods()
    {
        // These are integration tests that actually call systemctl
        // They will only work on systems with systemd

        if (!Utils::isProgramPresent(u"systemctl"_s)) {
            QSKIP("systemctl not available, skipping service state tests");
        }

        // Test with a service that should exist and be running
        QString state = m_systemUpdate->getServiceState(u"systemd-journald.service"_s);
        QVERIFY(!state.isEmpty());
        // journald is typically active on systemd systems

        // Test getServiceResult
        QString result = m_systemUpdate->getServiceResult(u"systemd-journald.service"_s);
        QVERIFY(!result.isEmpty());
        // Result should be something like "success" or other systemd result states
    }

    // Test that blockUpdate prevents further updates
    void testBlockUpdatePrevention()
    {
        QCOMPARE(m_systemUpdate->blockUpdate(), false);

        // Set block to true
        m_systemUpdate->setBlockUpdate(true);
        QCOMPARE(m_systemUpdate->blockUpdate(), true);

        // In actual usage, runUpdate checks blockUpdate (indirectly through service check)
        // Here we verify the property works
        QSignalSpy blockUpdateSpy(m_systemUpdate, &SystemUpdate::blockUpdateChanged);
        m_systemUpdate->setBlockUpdate(false);
        QCOMPARE(blockUpdateSpy.count(), 1);
        QCOMPARE(m_systemUpdate->blockUpdate(), false);
    }

    // Helper method to simulate journalctl message parsing
    void simulateJournalMessage(const QString &message)
    {
        // This simulates what logToConsole() does when parsing journalctl output
        if (!message.trimmed().startsWith(QLatin1Char('{'))) {
            // Plain text message
            m_systemUpdate->appendConsoleText(message, SystemUpdate::LogLevel::INFO);
        } else {
            // JSON message
            QJsonDocument sysDoc = QJsonDocument::fromJson(message.toUtf8());
            if (!sysDoc.isObject())
                return;

            QJsonObject obj = sysDoc.object();
            QString level = obj.value(u"level"_s).toString();
            QString msg = obj.value(u"msg"_s).toString();

            SystemUpdate::LogLevel log_level = SystemUpdate::LogLevel::WARN;

            if (level == u"DEBUG"_s) {
                log_level = SystemUpdate::LogLevel::DEBUG;
            } else if (level == u"INFO"_s) {
                log_level = SystemUpdate::LogLevel::INFO;
                // Extract progress level if present
                if (obj.contains(u"overall"_s)) {
                    m_systemUpdate->setProgressLevel(obj.value(u"overall"_s).toInt());
                }
            } else if (level == u"WARN"_s) {
                log_level = SystemUpdate::LogLevel::WARN;
            } else if (level == u"ERROR"_s) {
                log_level = SystemUpdate::LogLevel::ERROR;
            }

            if (!msg.isEmpty()) {
                m_systemUpdate->appendConsoleText(msg, log_level);
            }
        }
    }

    // Test parsing real example output
    void testRealExampleOutput()
    {
        QFile file(u"../tests/fixtures/example_output_1"_s);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QSKIP("Cannot open example_output_1 fixture file");
        }

        QSignalSpy progressSpy(m_systemUpdate, &SystemUpdate::progressLevelChanged);
        QSignalSpy consoleSpy(m_systemUpdate, &SystemUpdate::consoleTextChanged);

        QTextStream in(&file);
        while (!in.atEnd()) {
            QString line = in.readLine();
            simulateJournalMessage(line);
        }
        file.close();

        // Verify that console text was updated
        QVERIFY(consoleSpy.count() > 0);
        QString console = m_systemUpdate->consoleText();

        // Check for expected plain text messages
        QVERIFY(console.contains(u"Starting uupd-manual.service"_s));
        QVERIFY(console.contains(u"Finished uupd-manual.service"_s));

        // Check for expected JSON message content
        QVERIFY(console.contains(u"Hardware checks passed"_s));
        QVERIFY(console.contains(u"Updating"_s));
        QVERIFY(console.contains(u"Updates Completed Successfully"_s));

        // Verify progress levels were updated (should have 33, 67, 100 from the example)
        QVERIFY(progressSpy.count() >= 3);
        QCOMPARE(m_systemUpdate->progressLevel(), 100); // Final progress should be 100
    }

    // Test progress level extraction from INFO messages
    void testProgressLevelExtraction()
    {
        QSignalSpy progressSpy(m_systemUpdate, &SystemUpdate::progressLevelChanged);

        // Simulate INFO message with overall progress
        QString infoMsg =
            u"{\"level\":\"INFO\",\"msg\":\"Updating\",\"title\":\"Brew\",\"description\":\"CLI Apps\",\"progress\":0,\"total\":2,\"step_progress\":0,\"overall\":33}"_s;
        simulateJournalMessage(infoMsg);

        QCOMPARE(progressSpy.count(), 1);
        QCOMPARE(m_systemUpdate->progressLevel(), 33);

        // Another progress update
        infoMsg =
            u"{\"level\":\"INFO\",\"msg\":\"Updating\",\"title\":\"Flatpak\",\"description\":\"System Apps\",\"progress\":1,\"total\":2,\"step_progress\":0,\"overall\":67}"_s;
        simulateJournalMessage(infoMsg);

        QCOMPARE(progressSpy.count(), 2);
        QCOMPARE(m_systemUpdate->progressLevel(), 67);

        // Final progress
        infoMsg =
            u"{\"level\":\"INFO\",\"msg\":\"Updating\",\"title\":\"Flatpak\",\"description\":\"Apps for User: testUser\",\"progress\":2,\"total\":2,\"step_progress\":0,\"overall\":100}"_s;
        simulateJournalMessage(infoMsg);

        QCOMPARE(progressSpy.count(), 3);
        QCOMPARE(m_systemUpdate->progressLevel(), 100);
    }

    // Test DEBUG message handling with placeholder color
    void testDebugMessageHandling()
    {
        QString debugMsg = u"{\"level\":\"DEBUG\",\"msg\":\"Already up-to-date.\"}"_s;
        simulateJournalMessage(debugMsg);

        QString console = m_systemUpdate->consoleText();
        QVERIFY(console.contains(u"debug: Already up-to-date."_s));
        QVERIFY(console.contains(u"#888888"_s)); // Placeholder color
    }

    // Test plain text message handling
    void testPlainTextMessageHandling()
    {
        QString plainMsg = u"Starting uupd-manual.service - Universal Blue Update Oneshot Service..."_s;
        simulateJournalMessage(plainMsg);

        QString console = m_systemUpdate->consoleText();
        QVERIFY(console.contains(plainMsg));
        // Plain text is treated as INFO, so no bold formatting
        QVERIFY(!console.contains(u"<b>"_s + plainMsg));
    }

    // Test JSON message without progress field
    void testJSONMessageWithoutProgress()
    {
        QSignalSpy progressSpy(m_systemUpdate, &SystemUpdate::progressLevelChanged);

        QString infoMsg = u"{\"level\":\"INFO\",\"msg\":\"Hardware checks passed\"}"_s;
        simulateJournalMessage(infoMsg);

        // Progress should not change for messages without overall field
        QCOMPARE(progressSpy.count(), 0);
        QCOMPARE(m_systemUpdate->progressLevel(), 0);

        QString console = m_systemUpdate->consoleText();
        QVERIFY(console.contains(u"Hardware checks passed"_s));
    }

    // Test completion message
    void testCompletionMessage()
    {
        QString completionMsg = u"{\"level\":\"INFO\",\"msg\":\"Updates Completed Successfully\"}"_s;
        simulateJournalMessage(completionMsg);

        QString console = m_systemUpdate->consoleText();
        QVERIFY(console.contains(u"Updates Completed Successfully"_s));
    }

    // Test mixed plain text and JSON parsing
    void testMixedMessageTypes()
    {
        QSignalSpy consoleSpy(m_systemUpdate, &SystemUpdate::consoleTextChanged);

        // Plain text
        simulateJournalMessage(u"Starting service..."_s);

        // JSON INFO with progress
        simulateJournalMessage(u"{\"level\":\"INFO\",\"msg\":\"Processing\",\"overall\":50}"_s);

        // JSON DEBUG
        simulateJournalMessage(u"{\"level\":\"DEBUG\",\"msg\":\"Debug info\"}"_s);

        // Plain text completion
        simulateJournalMessage(u"Finished service."_s);

        QCOMPARE(consoleSpy.count(), 4);
        QString console = m_systemUpdate->consoleText();

        QVERIFY(console.contains(u"Starting service"_s));
        QVERIFY(console.contains(u"Processing"_s));
        QVERIFY(console.contains(u"debug: Debug info"_s));
        QVERIFY(console.contains(u"Finished service"_s));

        // Progress should have been set
        QCOMPARE(m_systemUpdate->progressLevel(), 50);
    }
};

QTEST_MAIN(TestSystemUpdate)
#include "test_system_update.moc"
