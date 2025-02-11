//
//  MessageActionsHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import FlowCryptUI
import UIKit

@MainActor
protocol MessageActionsHandler: AnyObject {
    var currentFolderPath: String { get }
    var trashFolderProvider: TrashFolderProviderType { get }

    func handleTrashTap()
    func handleInfoTap()
    func handleArchiveTap()
    func handleMoveToInboxTap()
    func handleMarkUnreadTap()

    func permanentlyDelete()
    func moveToTrash(with trashPath: String)
}

extension MessageActionsHandler where Self: UIViewController {
    private var logger: Logger {
        Logger.nested("MessageActions")
    }

    func setupNavigationBar(inboxItem: InboxItem) {
        Task {
            do {
                let path = try await trashFolderProvider.trashFolderPath
                setupNavigationBarItems(inboxItem: inboxItem, trashFolderPath: path)
            } catch {
                // todo - handle?
                logger.logError("setupNavigationBar: \(error)")
            }
        }
    }

    private func setupNavigationBarItems(inboxItem: InboxItem, trashFolderPath: String?) {
        logger.logInfo("setup navigation bar with \(trashFolderPath ?? "N/A")")
        logger.logInfo("currentFolderPath \(currentFolderPath)")

        let helpButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "questionmark.circle"),
            accessibilityId: "aid-help-button"
        ) { [weak self] in
            self?.handleInfoTap()
        }
        let archiveButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "tray.and.arrow.down"),
            accessibilityId: "aid-archive-button"
        ) { [weak self] in
            self?.handleArchiveTap()
        }
        let moveToInboxButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "tray.and.arrow.up"),
            accessibilityId: "aid-move-to-inbox-button"
        ) { [weak self] in
            self?.handleMoveToInboxTap()
        }
        let trashButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "trash"),
            accessibilityId: "aid-delete-button"
        ) { [weak self] in
            self?.handleTrashTap()
        }
        let unreadButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "envelope"),
            accessibilityId: "aid-read-button"
        ) { [weak self] in
            self?.handleMarkUnreadTap()
        }

        var items: [NavigationBarItemsView.Input]

        switch currentFolderPath.lowercased() {
        case trashFolderPath?.lowercased():
            logger.logInfo("trash - helpButton, moveToInboxButton, trashButton")
            // in case we are in trash folder ([Gmail]/Trash or Deleted for Outlook, etc)
            // we need to have only help, 'move to inbox' and trash buttons
            items = [helpButton, moveToInboxButton, trashButton]
        case "draft":
            // for Gmail inbox we also need to have archive and unread buttons
            logger.logInfo("draft - helpButton, trashButton")
            items = [helpButton, trashButton]
        default:
            // in any other folders
            items = [helpButton, trashButton, unreadButton]
            if inboxItem.isInbox {
                logger.logInfo("inbox - helpButton, archiveButton, trashButton, unreadButton")
                items.insert(archiveButton, at: 1)
            } else if inboxItem.shouldShowMoveToInboxButton {
                logger.logInfo("archive - helpButton, moveToInboxButton, trashButton, unreadButton")
                items.insert(moveToInboxButton, at: 1)
            } else {
                logger.logInfo("sent - helpButton, trashButton, unreadButton")
            }
        }

        navigationItem.rightBarButtonItem = NavigationBarItemsView(with: items)
    }

    func handleInfoTap() {
        showToast("Email us at human@flowcrypt.com")
    }

    func handleTrashTap() {
        Task {
            do {
                guard let trashPath = try await trashFolderProvider.trashFolderPath else {
                    return
                }

                deleteMessage(trashPath: trashPath)
            } catch {
                showToast(error.errorMessage)
            }
        }
    }

    private func deleteMessage(trashPath: String) {
        guard currentFolderPath.caseInsensitiveCompare(trashPath) != .orderedSame else {
            showAlertWithAction(
                title: "message_permanently_delete_title".localized,
                message: "message_permanently_delete".localized,
                actionButtonTitle: "delete".localized,
                actionStyle: .destructive,
                onAction: { [weak self] _ in
                    self?.permanentlyDelete()
                }
            )

            return
        }

        moveToTrash(with: trashPath)
    }
}
