//
//  Gmail+Backup.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import GoogleAPIClientForREST_Gmail

extension GmailService: BackupProvider {
    func searchBackups(for email: String) async throws -> Data {
        do {
            logger.logVerbose("will begin searching for backups")
            let query = try await backupSearchQueryProvider.makeBackupQuery(for: email)
            let backupMessages = try await searchExpression(using: MessageSearchContext(expression: query))
            logger.logVerbose("searching done, found \(backupMessages.count) backup messages")
            let uniqueMessages = Set(backupMessages)
            let attachmentContexts = uniqueMessages
                .compactMap { message -> [(String, String)]? in
                    logger.logVerbose("processing backup '\(message.subject ?? "-")' with \(message.attachmentIds.count) attachments")
                    guard let identifier = message.identifier.stringId else {
                        logger.logVerbose("skipping this last backup?")
                        return nil
                    }
                    return message.attachmentIds.map { (identifier, $0) }
                }
                .flatMap { $0 }
            var attachments: [Data] = []
            for attachmentContext in attachmentContexts {
                // todo - parallelize withTaskGroup
                attachments.append(try await findAttachment(attachmentContext))
            }
            logger.logVerbose("downloading \(attachments.count) attachments with possible backups in them")
            let data = attachments.joined
            logger.logVerbose("downloaded \(attachments.count) attachments that contain \(data.count / 1024)kB of data")
            return data
        } catch {
            throw GmailServiceError.missingBackupQuery(error)
        }
    }

    func findAttachment(_ context: (messageId: String, attachmentId: String)) async throws -> Data {
        let query = GTLRGmailQuery_UsersMessagesAttachmentsGet.query(
            withUserId: .me,
            messageId: context.messageId,
            identifier: context.attachmentId
        )
        return try await withCheckedThrowingContinuation { continuation in
            self.gmailService.executeQuery(query) { _, data, error in
                if let error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }
                guard let attachmentPart = data as? GTLRGmail_MessagePartBody else {
                    return continuation.resume(throwing: GmailServiceError.missingMessageInfo("findAttachment data"))
                }
                guard let data = GTLRDecodeBase64(attachmentPart.data) else {
                    return continuation.resume(throwing: GmailServiceError.messageEncode)
                }
                return continuation.resume(returning: data)
            }
        }
    }
}
