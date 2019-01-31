//
//  MainLMMViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

enum LMMType
{
    case likesYou
    case matches
    case messages
}

class MainLMMViewController: ThemeViewController
{
    var input: MainLMMVMInput!
    var type: BehaviorRelay<LMMType> = BehaviorRelay<LMMType>(value: .likesYou)
    
    var onChatShown: (()->())?
    var onChatHidden: (()->())?
    
    fileprivate var viewModel: MainLMMViewModel?
    fileprivate var feedDisposeBag: DisposeBag = DisposeBag()
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    fileprivate var isUpdated: Bool = true
    fileprivate var chatStartDate: Date? = nil
    fileprivate var prevScrollingOffset: CGFloat = 0.0
    fileprivate var isScrollTopVisible: Bool = false
    
    @IBOutlet fileprivate weak var emptyFeedLabel: UILabel!
    @IBOutlet fileprivate weak var chatContainerView: ContainerView!
    @IBOutlet fileprivate weak var chatConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var scrollTopBtn: UIButton!
    @IBOutlet fileprivate weak var tableView: UITableView!
    fileprivate var refreshControl: UIRefreshControl!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        let cellHeight = UIScreen.main.bounds.height * 3.0 / 4.0
        self.tableView.tableHeaderView = nil
        self.tableView.rowHeight = cellHeight
        self.tableView.estimatedRowHeight = cellHeight
        self.tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: UIScreen.main.bounds.height - cellHeight, right: 0.0)
        
        self.setupBindings()
        self.setupReloader()
    }
    
    @objc func onReload()
    {
        self.reload()
    }
    
    // MARK: - Actions
    
    @IBAction func onScrollTop()
    {
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0) , at: .top, animated: true)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = MainLMMViewModel(self.input)

        self.type.asObservable().subscribe(onNext:{ [weak self] type in
            self?.toggle(type)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func updateBindings()
    {
        self.feedDisposeBag = DisposeBag()
        self.isUpdated = true
        self.profiles()?.asObservable().subscribe(onNext: { [weak self] updatedProfiles in
            guard let `self` = self else { return }
            guard self.isUpdated else { return }
            
            self.isUpdated = updatedProfiles.count == 0
            self.emptyFeedLabel.text = self.placeholderText()
            self.emptyFeedLabel.isHidden = !updatedProfiles.isEmpty
            self.tableView.reloadData()
        }).disposed(by: self.feedDisposeBag)
    }
    
    fileprivate func setupReloader()
    {
        self.refreshControl = UIRefreshControl()
        self.tableView.addSubview(self.refreshControl)
        self.refreshControl.addTarget(self, action: #selector(onReload), for: .valueChanged)
    }
    
    fileprivate func reload()
    {
        self.isUpdated = true
        self.viewModel?.refresh().subscribe(onError:{ [weak self] error in
            guard let `self` = self else { return }
            
            showError(error, vc: self)
            }, onCompleted:{ [weak self] in
                self?.refreshControl.endRefreshing()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func toggle(_ type: LMMType)
    {
        self.updateBindings()
    }
    
    fileprivate func profiles() -> BehaviorRelay<[LMMProfile]>?
    {
        switch self.type.value {
        case .likesYou:
            return self.viewModel?.likesYou
            
        case .matches:
            return self.viewModel?.matches
            
        case .messages:
            return self.viewModel?.messages
        }
    }
    
    fileprivate func showChat(_ profile: LMMProfile, photo: Photo, indexPath: IndexPath, profileVC: MainLMMProfileViewController?)
    {
        self.chatStartDate = Date()
        
        let vc = ChatViewController.create()
        vc.input = ChatVMInput(profile: profile, photo: photo, chatManager: self.input.chatManager, source: .messages, onClose: { [weak self] in
            self?.hideChat(profileVC, profile: profile, photo: photo)
        })
        
        self.chatContainerView.embed(vc, to: self)
        self.chatConstraint.constant = -self.view.bounds.height
        
        self.onChatShown?()
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        profileVC?.hideControls()
        
        UIViewPropertyAnimator(duration: 0.35, curve: .easeOut, animations: {
            self.view.layoutSubviews()
        }).startAnimation()
    }
    
    fileprivate func hideChat(_ profileVC: MainLMMProfileViewController?, profile: LMMProfile, photo: Photo)
    {
        if let startDate = self.chatStartDate {
            let interval = Int(Date().timeIntervalSince(startDate))
            self.chatStartDate = nil
            
            self.input.actionsManager.add(
                .openChat(openChatCount: 1, openChatTimeSec: interval),
                profile: profile.actionInstance(),
                photo: photo.actionInstance(),
                source: self.type.value.sourceType()
            )
        }
        
        self.chatConstraint.constant = 0.0
        
        let animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeOut, animations: {
            self.view.layoutSubviews()
        })
        animator.addCompletion({ _ in
            profileVC?.showControls()
            self.chatContainerView.remove()
            self.onChatHidden?()
        })
        animator.startAnimation()
    }
    
    fileprivate func placeholderText() -> String
    {
        switch self.type.value {
        case .likesYou: return "Pull to refresh to\nsee who likes you"
        case .matches: return "Pull to refresh to\nsee your matches"
        case .messages: return "Pull to refresh to\nsee who messages you"
        }
    }
    
    fileprivate func showScrollToTopOption()
    {
        guard !self.isScrollTopVisible else { return }
        
        let animator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
            self.scrollTopBtn.alpha = 1.0
        }
        animator.addCompletion { _ in
            self.isScrollTopVisible = true
        }
        
        animator.startAnimation()
    }
    
    fileprivate func hideScrollToTopOption()
    {
        guard self.isScrollTopVisible else { return }
        
        let animator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
            self.scrollTopBtn.alpha = 0.0
        }
        animator.addCompletion { _ in
            self.isScrollTopVisible = false
        }
        
        animator.startAnimation()
    }
}

extension MainLMMViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.profiles()?.value.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "main_llm_cell") as! MainLMMCell
        if let profile = self.profiles()?.value[indexPath.row] {
            let profileVC = MainLMMProfileViewController.create(profile, feedType: self.type.value, actionsManager: self.input.actionsManager)
            profileVC.onChatShow = { [weak self] profile, photo, vc in
                self?.showChat(profile, photo: photo, indexPath: indexPath, profileVC: profileVC)
            }
            
            cell.containerView.embed(profileVC, to: self)
        }
        
        return cell
    }
}

fileprivate let topTrashhold: CGFloat = UIScreen.main.bounds.height
fileprivate let midTrashhold: CGFloat = UIScreen.main.bounds.width / 3.0 * 4.0

extension MainLMMViewController: UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        let offset = scrollView.contentOffset.y
        
        guard offset > topTrashhold else {
            self.hideScrollToTopOption()
            self.prevScrollingOffset = 0.0
            
            return
        }
        
        if offset - self.prevScrollingOffset < -1.0 * midTrashhold {
            self.showScrollToTopOption()
            self.prevScrollingOffset = offset
            
            return
        }
        
        if offset - self.prevScrollingOffset > midTrashhold {
            self.hideScrollToTopOption()
            self.prevScrollingOffset = offset
            
            return
        }
    }
}
