//
//  TemperatureFetching.swift
//  ElfOnAShelf
//
//  Created by Anne Cahalan on 1/6/18.
//  Copyright © 2018 Anne Cahalan. All rights reserved.
//

import Foundation
import UIKit

protocol TemperatureFetching {
    
    var state: String { get }
    var city: String { get }
    
    var temperatureLabel: UILabel! { get }
    
    func fetchTemperature(closure: @escaping (TemperatureInfo) -> Void)
}

extension TemperatureFetching {
    
    func fetchTemperature(closure: @escaping (TemperatureInfo) -> Void) {
        guard let url = URL(string: "https://api.wunderground.com/api/b193c8afeeecdbb2/conditions/q/\(state)/\(city).json") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let session = URLSession.shared
        
        session.dataTask(with: request) { data, response, error in
            if error != nil {
                print("🚨🚨🚨🚨🚨 \(error.debugDescription)")
            } else {
                guard let newData = data else { return }
                let jsonString = String(data: newData, encoding: String.Encoding.utf8)
                
                guard let jsonData = jsonString?.data(using: .utf8) else { return }
                let decoder = JSONDecoder()
                let decodedData = try? decoder.decode(CurrentObservation.self, from: jsonData)
                
                guard let weatherWeCareAbout = decodedData?.current_observation else { return }
                closure(weatherWeCareAbout)
            }
            }.resume()
    }
    
}

struct CurrentObservation: Codable {
    let current_observation: TemperatureInfo
}

struct TemperatureInfo: Codable {
    let weather: String
    let temp: Double
    let windchill: String
 
    private enum CodingKeys: String, CodingKey {
        case weather, temp = "temp_f", windchill = "windchill_f"
    }
}



