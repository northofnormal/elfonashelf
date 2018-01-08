//
//  SantaClausViewController.swift
//  ElfOnAShelf
//
//  Created by Anne Cahalan on 1/6/18.
//  Copyright © 2018 Anne Cahalan. All rights reserved.
//

import UIKit

class SantaClausViewController: UIViewController {
    
    @IBOutlet weak var temperatureLabel: UILabel!
    
    @IBAction func swipeRight() {
        swipe(direction: "SantaClausToNorthPole")
    }
    
    var city = "Santa_Claus"
    var state = "IN"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchTemperature { info in
            DispatchQueue.main.async {
                self.temperatureLabel.text = "weather: \(info.weather), temp: \(info.temp), windchill: \(info.windchill)"
            }
        }
    }

}

extension SantaClausViewController: Swipable { }

extension SantaClausViewController: TemperatureFetching { }
