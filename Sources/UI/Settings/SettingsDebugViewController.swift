//
//  SettingsDebugViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 26/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

struct SettingsDebugVCInput
{
    let actionsManager: ActionsManager
    let errorsManager: ErrorsManager
}

struct DebugErrorItem
{
    let title: String
    let trigger: (() -> ())?
}

class SettingsDebugViewController: BaseViewController
{
    var input: SettingsDebugVCInput!
    
    fileprivate var items: [DebugErrorItem] = []
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: .zero)
        
        self.items = [
            DebugErrorItem(title: "No Internet", trigger: { [weak self] in
                self?.input.actionsManager.isInternetAvailable.accept(false)
            }),
            DebugErrorItem(title: "Internal Server Error", trigger: { [weak self] in
                self?.input.errorsManager.simulatedError.accept(ApiError(type: .internalServerError))
            }),
            DebugErrorItem(title: "Invalid Access Token", trigger: { [weak self] in
                self?.input.errorsManager.simulatedError.accept(ApiError(type: .invalidAccessTokenClientError))
            }),
            DebugErrorItem(title: "Too Old App version", trigger: { [weak self] in
                self?.input.errorsManager.simulatedError.accept(ApiError(type: .tooOldAppVersionClientError))
            }),
            DebugErrorItem(title: "Response code not 200", trigger: { [weak self] in
                self?.input.errorsManager.simulatedError.accept(ApiError(type: .non200StatusCode))
            }),
            DebugErrorItem(title: "Timeout", trigger: { [weak self] in
                self?.input.errorsManager.simulatedError.accept(ApiError(type: .connectionTimeout))
            }),
        ]
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    // MARK: - Actions
    
    @IBAction func onBack()
    {
        self.navigationController?.popViewController(animated: true)
    }
}

extension SettingsDebugViewController: UITableViewDataSource, UITableViewDelegate
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "debug_item_cell") as! SettingsDebugItemCell
        
        cell.item = self.items[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        self.items[indexPath.row].trigger?()
    }
}
