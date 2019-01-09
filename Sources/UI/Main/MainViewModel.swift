//
//  MainViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 09/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct MainVMInput
{
    let newFacesManager: NewFacesManager
}

class MainViewModel
{
    let input: MainVMInput
    
    init(_ input: MainVMInput)
    {
        self.input = input
    }
}
