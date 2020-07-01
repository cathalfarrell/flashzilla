//
//  Card.swift
//  Flashzilla
//
//  Created by Cathal Farrell on 30/06/2020.
//  Copyright © 2020 Cathal Farrell. All rights reserved.
//

import Foundation

struct Card: Codable {
    let prompt: String
    let answer: String

    static var example: Card {
        Card(prompt: "Who played the 13th Doctor in Doctor Who?", answer: "Jodie Whittaker")
    }
}
