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

class ChatViewController: BaseViewController
{
    var input: ChatVMInput!
    
    fileprivate var viewModel: ChatViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    fileprivate static var messagesCache: [String: String] = [:]
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var messageTextView: UITextView!
    @IBOutlet fileprivate weak var inputBottomConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var inputHeightConstraint: NSLayoutConstraint!
    
    static func create() -> ChatViewController
    {
        let storyboard = Storyboards.chat()
        
        return storyboard.instantiateInitialViewController() as! ChatViewController
    }
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        KeyboardListener.shared.delegate = self
        
        self.tableView.transform = CGAffineTransform(rotationAngle: -.pi)
        
        self.messageTextView.text = ChatViewController.messagesCache[self.input.profile.id]
        
        self.setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.messageTextView.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        let width: CGFloat = 76.0
        let height: CGFloat = 56.0
        (self.view as? TouchThroughAreaView)?.area = CGRect(
            x: self.view.bounds.width - width,
            y: self.view.safeAreaInsets.top,
            width: width,
            height: height
        )
    }
    
    override func updateTheme()
    {
        let theme = ThemeManager.shared.theme.value
        self.messageTextView.keyboardAppearance = theme == .dark ? .dark : .light
    }
    
    override func updateLocale()
    {
        
    }
    
    // MARK: - Actions
    
    @IBAction func onClose()
    {
        self.viewModel?.markAsRead()
        ChatViewController.messagesCache[self.input.profile.id] = self.messageTextView.text
        
        self.messageTextView.resignFirstResponder()
        self.input.onClose?()
    }
    
    @IBAction func onSend()
    {
        let text = self.messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard text.count > 0 else { return }
        
        let shouldCloseAutomatically = self.viewModel?.messages.value.count == 0
        
        self.viewModel?.send(text)
        
        self.messageTextView.text = ""
        
        guard !shouldCloseAutomatically else {
            self.onClose()
            
            return
        }
        
        self.inputHeightConstraint.constant = 40.0
        self.view.layoutSubviews()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = ChatViewModel(self.input)
        
        self.viewModel?.messages.asObservable().subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
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
        
        cell.message = message
        
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
        guard let text = textView.text else { return }
        guard text.count != 0 else {
            self.inputHeightConstraint.constant = 40.0
            self.view.layoutSubviews()
            
            return
        }
        
        let font = textView.font!
        let currentHeight = tableView.bounds.size.height
        let textHeight = self.textSize(text).height
        
        guard Int(textHeight / font.lineHeight) <= 4 else { return }
        
        let height = textHeight + 22.0

        guard abs(currentHeight - height) > 1.0 else { return }
        
        self.inputHeightConstraint.constant = height
        self.view.layoutSubviews()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    {
        guard text != "" else { return true } // always allowing backspaces
        
        let contentText = textView.text as NSString
        contentText.replacingCharacters(in: range, with: text)
        
        return contentText.length <= 1000
    }
}
