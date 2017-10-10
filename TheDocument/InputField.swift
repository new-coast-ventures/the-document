//
//  InputField.swift
//  TheDocument
//


import Foundation
import UIKit
class InputField: UITextField {
    override func awakeFromNib() {
        super.awakeFromNib()
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0.0, y: self.frame.height - 1, width: self.frame.width, height: 1.0)
        bottomLine.backgroundColor = Constants.Theme.grayColor.cgColor
        self.borderStyle = .none
        self.layer.addSublayer(bottomLine)
    }
}
