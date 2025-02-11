//
//  UIViewControllerExtension.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/20/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import MBProgressHUD
import Toast
import UIKit

// MARK: - Toast
public typealias ShowToastCompletion = (Bool) -> Void
public extension UIViewController {
    /// Showing toast on root controller
    ///
    /// - Parameters:
    ///   - message: Message to be shown
    ///   - title: Title for the toast
    ///   - duration: Toast presented duration. Default is 3.0
    ///   - position: Bottom by default. Can be top, center, bottom.
    ///   - shouldHideKeyboard: True by default. Hide keyboard when toast is presented
    ///   - completion: Notify when toast dissappeared
    @MainActor
    func showToast(
        _ message: String,
        title: String? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .bottom,
        shouldHideKeyboard: Bool = true,
        completion: ShowToastCompletion? = nil
    ) {
        guard let view = UIApplication.shared.currentWindow?.rootViewController?.view else {
            assertionFailure("Key window hasn't rootViewController")
            return
        }
        view.hideAllToasts()

        if shouldHideKeyboard {
            view.endEditing(true)
        }

        view.makeToast(
            message,
            duration: duration,
            position: position,
            title: title,
            completion: completion
        )

        ToastManager.shared.isTapToDismissEnabled = true
    }
}

// MARK: - Alerts
public extension UIViewController {
    @MainActor
    func showAlert(title: String? = "error".localized, message: String, onOk: (() -> Void)? = nil) {
        view.hideAllToasts()
        hideSpinner()
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let ok = UIAlertAction(
            title: "ok".localized,
            style: .destructive
        ) { _ in onOk?() }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }

    @MainActor
    func showAsyncAlert(title: String? = "error".localized, message: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            showAlert(title: title, message: message) {
                return continuation.resume()
            }
        }
    }

    @MainActor
    func showAlertWithAction(
        title: String?,
        message: String?,
        cancelButtonTitle: String = "cancel".localized,
        actionButtonTitle: String,
        actionAccessibilityIdentifier: String? = nil,
        actionStyle: UIAlertAction.Style = .default,
        onAction: ((UIAlertAction) -> Void)?,
        onCancel: ((UIAlertAction) -> Void)? = nil
    ) {
        view.hideAllToasts()
        hideSpinner()
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let action = UIAlertAction(
            title: actionButtonTitle,
            style: actionStyle,
            handler: onAction
        )
        action.accessibilityIdentifier = actionAccessibilityIdentifier
        let cancel = UIAlertAction(
            title: cancelButtonTitle,
            style: .cancel,
            handler: onCancel
        )
        cancel.accessibilityIdentifier = "aid-cancel-button"
        alert.addAction(action)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }

    @MainActor
    func showRetryAlert(
        title: String? = "error".localized,
        message: String,
        cancelButtonTitle: String = "cancel".localized,
        onRetry: ((UIAlertAction) -> Void)?,
        onCancel: ((UIAlertAction) -> Void)? = nil
    ) {
        showAlertWithAction(
            title: title,
            message: message,
            cancelButtonTitle: cancelButtonTitle,
            actionButtonTitle: "retry_title".localized,
            onAction: onRetry,
            onCancel: onCancel
        )
    }

    @MainActor
    func showConfirmAlert(message: String, onConfirm: ((UIAlertAction) -> Void)?) {
        showAlertWithAction(
            title: "warning".localized,
            message: message,
            actionButtonTitle: "confirm".localized,
            actionAccessibilityIdentifier: "aid-confirm-button",
            onAction: onConfirm
        )
    }

    func keyboardHeight(from notification: Notification) -> CGFloat {
        (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0
    }
}

// MARK: - Navigation
public extension UINavigationController {
    func pushViewController(viewController: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        pushViewController(viewController, animated: animated)

        if let transitionCoordinator, animated {
            transitionCoordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }

    func popViewController(animated: Bool, completion: @escaping () -> Void) {
        popViewController(animated: animated)

        if let transitionCoordinator, animated {
            transitionCoordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }
}

// MARK: - MBProgressHUD
public extension UIViewController {
    var currentProgressHUD: MBProgressHUD {
        MBProgressHUD.forView(view) ?? MBProgressHUD.showAdded(to: view, animated: true)
    }

    @MainActor
    func showSpinner(_ message: String = "loading_title".localized, isUserInteractionEnabled: Bool = false) {
        guard !view.subviews.contains(where: { $0 is MBProgressHUD }) else {
            // hud is already shown
            return
        }
        view.isUserInteractionEnabled = isUserInteractionEnabled

        let spinner = MBProgressHUD.showAdded(to: view, animated: true)
        spinner.label.text = message
        spinner.isUserInteractionEnabled = isUserInteractionEnabled
        spinner.accessibilityIdentifier = "loadingSpinner"
    }

    @MainActor
    func updateSpinner(
        label: String = "compose_uploading".localized,
        progress: Float? = nil,
        systemImageName: String? = nil
    ) {
        guard let progress else {
            showIndeterminateHUD(with: label)
            return
        }

        if progress >= 1, let imageName = systemImageName {
            updateSpinner(
                label: "compose_sent".localized,
                systemImageName: imageName
            )
        } else {
            showProgressHUD(progress: progress, label: label)
        }
    }

    @MainActor
    func hideSpinner() {
        let subviews = view.subviews.compactMap { $0 as? MBProgressHUD }
        for subview in subviews {
            subview.hide(animated: true)
        }
        view.isUserInteractionEnabled = true
    }

    @MainActor
    func showProgressHUD(progress: Float, label: String) {
        let percent = Int(progress * 100)
        currentProgressHUD.label.text = "\(label) \(percent)%"
        currentProgressHUD.progress = progress
        currentProgressHUD.mode = .annularDeterminate
    }

    @MainActor
    func showProgressHUDWithCustomImage(imageName: String, label: String) {
        let configuration = UIImage.SymbolConfiguration(pointSize: 36)
        let imageView = UIImageView(image: .init(systemName: imageName, withConfiguration: configuration))
        currentProgressHUD.minSize = CGSize(width: 150, height: 90)
        currentProgressHUD.customView = imageView
        currentProgressHUD.mode = .customView
        currentProgressHUD.label.text = label
    }

    @MainActor
    func showIndeterminateHUD(with title: String) {
        currentProgressHUD.mode = .indeterminate
        currentProgressHUD.label.text = title
    }
}
