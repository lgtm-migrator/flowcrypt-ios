//
//  ThreadMessageSenderCellNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 06/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import UIKit

public final class ThreadMessageSenderCellNode: CellNode {
    public struct Input {
        public let encryptionBadge: BadgeNode.Input
        public let signatureBadge: BadgeNode.Input?
        public let sender: NSAttributedString
        public let date: NSAttributedString?
        public let isExpanded: Bool
        public let buttonColor: UIColor
        public let nodeInsets: UIEdgeInsets

        public init(encryptionBadge: BadgeNode.Input,
                    signatureBadge: BadgeNode.Input?,
                    sender: NSAttributedString,
                    date: NSAttributedString,
                    isExpanded: Bool,
                    buttonColor: UIColor,
                    nodeInsets: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 12)) {
            self.encryptionBadge = encryptionBadge
            self.signatureBadge = signatureBadge
            self.sender = sender
            self.date = date
            self.isExpanded = isExpanded
            self.buttonColor = buttonColor
            self.nodeInsets = nodeInsets
        }

        var replyImage: UIImage? {
            return createButtonImage(systemName: "arrowshape.turn.up.left")
        }
        var expandImage: UIImage? {
            let systemName = isExpanded ? "chevron.up" : "chevron.down"
            return createButtonImage(systemName: systemName)
        }

        private func createButtonImage(systemName: String, pointSize: CGFloat = 18) -> UIImage? {
            let configuration = UIImage.SymbolConfiguration(pointSize: pointSize)
            return UIImage(systemName: systemName, withConfiguration: configuration)
        }
    }

    private lazy var encryptionNode: BadgeNode = {
        return BadgeNode(input: input.encryptionBadge)
    }()

    private lazy var signatureNode: BadgeNode? = {
        return input.signatureBadge.map(BadgeNode.init)
    }()

    private let senderNode = ASTextNode2()
    private let dateNode = ASTextNode2()

    public private(set) var replyNode = ASButtonNode()
    public private(set) var expandNode = ASImageNode()

    private let input: ThreadMessageSenderCellNode.Input
    private var onReplyTap: ((ThreadMessageSenderCellNode) -> Void)?

    public init(input: ThreadMessageSenderCellNode.Input,
                onReplyTap: ((ThreadMessageSenderCellNode) -> Void)?) {
        self.input = input
        self.onReplyTap = onReplyTap
        super.init()
        automaticallyManagesSubnodes = true

        senderNode.attributedText = input.sender
        senderNode.accessibilityIdentifier = "senderEmail"
        dateNode.attributedText = input.date


        setupReplyNode()
        setupExpandNode()
    }

    private func setupReplyNode() {
        replyNode.setImage(input.replyImage, for: .normal)
        replyNode.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(input.buttonColor)
        replyNode.contentMode = .center
        replyNode.alpha = input.isExpanded ? 1 : 0
        replyNode.addTarget(self, action: #selector(onReplyNodeTap), forControlEvents: .touchUpInside)
        replyNode.accessibilityIdentifier = "replyButton"
    }

    private func setupExpandNode() {
        expandNode.image = input.expandImage
        expandNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(input.buttonColor)
        expandNode.contentMode = .right
    }

    @objc private func onReplyNodeTap() {
        onReplyTap?(self)
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        replyNode.style.preferredSize = CGSize(width: 44, height: 44)
        expandNode.style.preferredSize = CGSize(width: 18, height: 44)

        let infoNode = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: [senderNode, dateNode]
        )
        infoNode.style.flexGrow = 1
        infoNode.style.flexShrink = 1

        let senderSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 4,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: [infoNode, replyNode, expandNode]
        )

        let contentSpec: ASStackLayoutSpec
        if input.isExpanded {
            let spacer = ASLayoutSpec()
            spacer.style.flexGrow = 1.0

            var children: [ASLayoutElement] = []
            children.append(encryptionNode)
            if let signatureNode = signatureNode {
                children.append(signatureNode)
            }
            children.append(spacer)

            let signatureSpec = ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 4,
                justifyContent: .spaceBetween,
                alignItems: .start,
                children: children
            )

            contentSpec = ASStackLayoutSpec(
                direction: .vertical,
                spacing: 4,
                justifyContent: .spaceBetween,
                alignItems: .stretch,
                children: [senderSpec, signatureSpec]
            )
        } else {
            contentSpec = senderSpec
        }

        return ASInsetLayoutSpec(
            insets: input.nodeInsets,
            child: contentSpec
        )
    }
}
