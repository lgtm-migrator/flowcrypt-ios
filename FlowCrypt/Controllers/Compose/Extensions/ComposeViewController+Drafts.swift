//
//  ComposeViewController+Drafts.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

// MARK: - Drafts
extension ComposeViewController {
    @objc func startDraftTimer(withFire: Bool = false) {
        guard saveDraftTimer == nil else { return }

        saveDraftTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.saveDraftIfNeeded()
        }

        if withFire {
            saveDraftTimer?.fire()
        }
    }

    @objc func stopDraftTimer(withSave: Bool = true) {
        guard saveDraftTimer != nil else { return }

        saveDraftTimer?.invalidate()
        saveDraftTimer = nil

        if withSave {
            saveDraftIfNeeded()
        }
    }

    private func createDraft() -> ComposedDraft? {
        let newDraft = ComposedDraft(
            input: input,
            contextToSend: contextToSend
        )

        guard let existingDraft = composedLatestDraft else {
            composedLatestDraft = newDraft
            return nil
        }

        return newDraft != existingDraft ? newDraft : nil
    }

    func saveDraftIfNeeded(handler: ((DraftSaveState) -> Void)? = nil) {
        guard let draft = createDraft() else {
            handler?(.cancelled)
            return
        }

        handler?(.saving(draft))

        Task {
            do {
                let shouldEncrypt = draft.input.type.info?.shouldEncrypt == true ||
                    contextToSend.hasRecipientsWithActivePubKey

                let sendableMsg = try await composeMessageService.validateAndProduceSendableMsg(
                    input: draft.input,
                    contextToSend: draft.contextToSend,
                    isDraft: true,
                    withPubKeys: shouldEncrypt
                )

                try await composeMessageService.saveDraft(
                    message: sendableMsg,
                    threadId: draft.input.threadId,
                    shouldEncrypt: shouldEncrypt
                )

                composedLatestDraft = draft
                handler?(.success(sendableMsg))
            } catch {
                if !(error is MessageValidationError) {
                    // no need to save or notify user if validation error
                    // for other errors show toast
                    showToast("draft_error".localizeWithArguments(error.errorMessage), position: .top)
                }
                handler?(.error(error))
            }
        }
    }
}
