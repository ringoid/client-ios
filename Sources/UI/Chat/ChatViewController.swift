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

class ChatViewController: UIViewController
{
    var input: ChatVMInput!
    
    fileprivate var viewModel: ChatViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var messageTextView: UITextView!
    @IBOutlet fileprivate weak var inputBottomConstraint: NSLayoutConstraint!
    
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
        
        self.setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.messageTextView.becomeFirstResponder()
    }
    
    // MARK: - Actions
    
    @IBAction func onClose()
    {
        self.messageTextView.resignFirstResponder()
        self.input.onClose?()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = ChatViewModel(self.input)
        
        self.viewModel?.messages.asObservable().subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: self.disposeBag)
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
        guard let message = self.viewModel?.messages.value[indexPath.row] else { return UITableViewCell() }
        let identifier = message.wasYouSender ? "chat_right_cell" : "chat_left_cell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? ChatBaseCell else { return UITableViewCell() }
        
        cell.message = message
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        guard let message = self.viewModel?.messages.value[indexPath.row] else { return 0.0 }
        
        return ChatBaseCell.height(message.text)
    }
}

extension ChatViewController: KeyboardListenerDelegate
{
    func keyboardListener(_ listener: KeyboardListener, animationFor keyboardHeight: CGFloat) -> (() -> ())?
    {
        self.inputBottomConstraint.constant = keyboardHeight
        
        return { [weak self] in
            self?.view.layoutSubviews()
        }
    }
}
