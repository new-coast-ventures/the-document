//
//  Comment.swift
//  TheDocument
//
//  Created by Scott Kacyn on 7/18/17.
//  Copyright © 2017 Mruvka. All rights reserved.
//

import UIKit

class Comment: NSObject {
    var uid: String
    var author: String
    var text: String
    
    init(uid: String, author: String, text: String) {
        self.uid = uid
        self.author = author
        self.text = text
    }
    
    convenience override init() {
        self.init(uid: "", author: "", text: "")
    }
}
