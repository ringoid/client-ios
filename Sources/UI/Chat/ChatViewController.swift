//
//  ChatViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Nuke
import Differ

class ChatViewController: BaseViewController
{
    var input: ChatVMInput!
    
    static var openedProfileId: String? = nil
    
    fileprivate var viewModel: ChatViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    fileprivate static var messagesCache: [String: String] = [:]
    fileprivate var sendingMessagesIds: [String] = []
    fileprivate var cellIdsMap: [String: ChatRightCell] = [:]
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var messageTextView: UITextView!
    @IBOutlet fileprivate weak var photoView: UIImageView!
    @IBOutlet fileprivate weak var statusView: UIView!
    @IBOutlet fileprivate weak var statusLabel: UILabel!
    @IBOutlet fileprivate weak var inputBottomConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var inputHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var statusCenterOffsetConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var nameCenterOffsetConstraint: NSLayoutConstraint!
    
    @IBOutlet fileprivate weak var clipboardLabel: UILabel!
    
    static func create() -> ChatViewController
    {
        let storyboard = Storyboards.chat()
        
        return storyboard.instantiateInitialViewController() as! ChatViewController
    }
    
    static func resetCache()
    {
        ChatViewController.messagesCache.removeAll()
    }
    
    deinit
    {
        ChatViewController.openedProfileId = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        ChatViewController.openedProfileId = self.input.profile.id               
        
        self.setupInputAttributes()
        KeyboardListener.shared.delegate = self
        
        self.tableView.transform = CGAffineTransform(rotationAngle: -.pi)
        
        self.messageTextView.text = ChatViewController.messagesCache[self.input.profile.id]
        
        self.statusView.layer.borderWidth = 1.0
        self.statusView.layer.borderColor = UIColor.lightGray.cgColor
        self.applyStatuses()
        
        if let url = self.input.photo.filepath().url() {
            ImageService.shared.load(url, thumbnailUrl: self.input.photo.thumbnailFilepath().url(), to: self.photoView)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(onAppBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        self.setupBindings()
        self.textViewDidChange(self.messageTextView)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.messageTextView.becomeFirstResponder()
        
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        self.tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: self.tableView.bounds.width - 10.0)
        self.tableView.contentInset = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 0.0, right: 0.0)		        
    }   
    
    override func updateTheme()
    {
        let theme = ThemeManager.shared.theme.value
        self.messageTextView.keyboardAppearance = theme == .dark ? .dark : .light
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.clipboardLabel.text = "common_clipboard".localized()
    }
    
    // MARK: - Actions
    
    @IBAction func onClose()
    {
        self.closeChat(false)
    }
    
    @IBAction func onSend()
    {
        guard self.input.chatManager.actionsManager.checkConnectionState() else { return }
        
        defer {
            self.messageTextView.text = ""
            self.inputHeightConstraint.constant = 40.0
            self.view.layoutSubviews()
            ChatViewController.messagesCache.removeValue(forKey: self.input.profile.id)
        }
        
        let text = self.messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard text.count > 0 else {
            return
        }
        
        self.viewModel?.send(text)
    }
    
    @IBAction func onBlock()
    {
        guard self.input.chatManager.actionsManager.checkConnectionState() else { return }
        
        self.input.onBlock?()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = ChatViewModel(self.input)
        
        self.viewModel?.messages.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] updatedMessages in
            guard let `self` = self else { return }
            
            // Analytics
            var isMyMessageAppeared: Bool = false
            for message in updatedMessages {
                if !message.wasYouSender {
                    self.input.scenario.checkFirstMessageReceived(self.input.source)
                    
                    if isMyMessageAppeared {
                        self.input.scenario.checkFirstReplyReceived(self.input.source)
                        
                        break
                    }
                } else {
                    isMyMessageAppeared = true
                }
            }
            
            self.cellIdsMap.removeAll()
            self.tableView.reloadData()
            DispatchQueue.main.async {
                self.updateVisibleCellsBorders(self.tableView.contentOffset.y)
            }
            
            if self.viewModel?.messages.value.count != 0 {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        }).disposed(by: self.disposeBag)
        
        Observable.from(object:self.input.profile).observeOn(MainScheduler.instance).subscribe({ [weak self] _ in
            self?.applyStatuses()
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.activeSendingActions.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self]  messagesIds in
            guard let `self` = self else { return }
            
            let diff = patch(from: self.sendingMessagesIds, to: messagesIds)

            guard !diff.isEmpty else { return }

            diff.forEach { path in
                switch path {
                case .insertion(_, let messageId):
                    self.cellIdsMap[messageId]?.state = .sending
                    break
                    
                case .deletion(let index):
                    let messageId = self.sendingMessagesIds[index]
                    self.cellIdsMap[messageId]?.state = .sent
                    break
                }
            }

            self.sendingMessagesIds = messagesIds
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func textSize(_ text: String) -> CGSize
    {
        guard let font = self.messageTextView.font else { return .zero }
        let currentSize = self.messageTextView.bounds.size
        let maxWidth = currentSize.width - 18.0

        return (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: 200.0),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font],
            context: nil
            ).size
    }
    
    @objc fileprivate func onAppBecomeActive()
    {
        self.messageTextView.becomeFirstResponder()
        self.viewModel?.updateContent()
    }
    
    fileprivate func setupInputAttributes()
    {
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.88)
        shadow.shadowOffset = CGSize(width: 1.0, height: 1.0)
        shadow.shadowBlurRadius = 2.0
        
        self.messageTextView.typingAttributes = [
            .font: UIFont.systemFont(ofSize: 15.0),
            .foregroundColor: UIColor.white,
            .shadow: shadow
        ]
    }
    
    fileprivate func applyStatuses()
    {
        // Status
        
        if let status = OnlineStatus(rawValue: self.input.profile.status), status != .unknown {
            self.statusView.backgroundColor = status.color()
            self.statusView.isHidden = false
            self.nameCenterOffsetConstraint.constant = 3.0
            self.statusCenterOffsetConstraint.constant = 19.0
        } else {
            self.statusView.isHidden = true
            self.nameCenterOffsetConstraint.constant =  10.0
            self.statusCenterOffsetConstraint.constant = 10.0
        }
        
        if let statusText = self.input.profile.statusText, statusText.lowercased() != "unknown",  statusText.count > 0 {
            self.statusLabel.text = statusText
            self.statusLabel.isHidden = false
        } else {
            self.statusLabel.isHidden = true
        }
        
        // Name
        let profile = self.input.profile
        var title: String = ""
        if let name = profile.name, name != "unknown" {
            title += name
        } else if let genderStr = profile.gender, let gender = Sex(rawValue: genderStr) {
            let genderStr = gender == .male ? "common_sex_male".localized() : "common_sex_female".localized()
            title += genderStr
        }
        
        self.nameLabel.text = title
    }
    
    fileprivate func updateVisibleCellsBorders(_  contentOffset: CGFloat)
    {
        let tableBottomOffset = contentOffset + self.tableView.bounds.height
        
        // Cells
        self.tableView.visibleCells.forEach { cell in
            guard let chatCell = cell as? ChatBaseCell else { return }
            guard let index = self.tableView.indexPath(for: cell)?.row else { return }
            
            let cellTopOffset = CGFloat(index) * cell.bounds.height
            let cellBottomOffset = cellTopOffset + cell.bounds.height - 32.0
            
            chatCell.topVisibleBorderDistance = tableBottomOffset - cellBottomOffset + self.view.safeAreaInsets.top
        }
    }
    
    func closeChat(_ shouldMoveToMessages: Bool)
    {        
        self.viewModel?.markAsRead()
        ChatViewController.messagesCache[self.input.profile.id] = self.messageTextView.text
        
        self.messageTextView.resignFirstResponder()
        self.input.onClose?()
    }
    
    fileprivate func updateInputLayout(_ text: String)
    {
        guard text.count != 0 else {
            self.inputHeightConstraint.constant = 40.0
            self.view.layoutSubviews()
            
            return
        }
        
        let font = self.messageTextView.font!
        let currentHeight = self.messageTextView.bounds.height
        let textHeight = self.textSize(text).height
        
        guard Int(textHeight / font.lineHeight) <= 4 else {
            let baseHeight = font.lineHeight * 4.0
            let height = baseHeight + 22.0
            if abs(currentHeight - height) < 1.0 { return }
            
            self.inputHeightConstraint.constant = height
            self.view.layoutSubviews()
            
            return
        }
        
        let height = textHeight + 22.0
        
        guard abs(currentHeight - height) > 1.0 else { return }
        
        self.inputHeightConstraint.constant = height
        self.view.layoutSubviews()
    }
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.viewModel?.messages.value.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let message = self.viewModel?.messages.value.reversed()[indexPath.row] else { return UITableViewCell() }
        let identifier = message.wasYouSender ? "chat_right_cell" : "chat_left_cell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? ChatBaseCell else { return UITableViewCell() }
        
        if message.wasYouSender, let rightCell = cell as? ChatRightCell {
            rightCell.state = self.sendingMessagesIds.contains(message.id) ? .sending : .sent
            self.cellIdsMap[message.id] = rightCell
        }
        
        cell.message = message
        cell.onCopyMessage = { [weak self] text in
            UIPasteboard.general.string = text
            
            let appearAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut, animations: {
                self?.clipboardLabel.alpha = 1.0
            })
            
            let disappearAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut, animations: {
                self?.clipboardLabel.alpha = 0.0
            })
            
            appearAnimator.addCompletion({ _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                    disappearAnimator.startAnimation()
                })
            })
            
            appearAnimator.startAnimation()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        guard let message = self.viewModel?.messages.value.reversed()[indexPath.row] else { return 0.0 }
        
        return ChatBaseCell.height(message.text)
    }
}

extension ChatViewController: KeyboardListenerDelegate
{
    func keyboardListener(_ listener: KeyboardListener, animationFor keyboardHeight: CGFloat) -> (() -> ())?
    {
        self.inputBottomConstraint.constant = keyboardHeight

        return nil
    }
}

extension ChatViewController: UITextViewDelegate
{
    func textViewDidChange(_ textView: UITextView)
    {
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    {
        var contentText: String = textView.text
        contentText = (contentText as NSString).replacingCharacters(in: range, with: text) as String
        
        guard text != "" else { // always allowing backspaces
            self.updateInputLayout(contentText)
            
            return true
        }
    
        let result = contentText.count <= 1000
        if result {
            self.updateInputLayout(contentText)
        }
        
        return result
    }
    
    // Cursor color fix
    func textViewDidBeginEditing(_ textView: UITextView)
    {
        let color = textView.tintColor
        textView.tintColor = .clear
        textView.tintColor = color
    }
}

extension ChatViewController: UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        let offset = scrollView.contentOffset.y
        self.updateVisibleCellsBorders(offset)
    }
}
