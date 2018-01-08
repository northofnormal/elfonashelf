//
//  Swipable.swift
//  ElfOnAShelf
//
//  Created by Anne Cahalan on 1/6/18.
//  Copyright © 2018 Anne Cahalan. All rights reserved.
//

import Foundation
import UIKit

protocol Swipable { }

extension Swipable where Self: UIViewController {
    
    func swipe(direction: String) {
        performSegue(withIdentifier: direction, sender: self)
    }
    
}
