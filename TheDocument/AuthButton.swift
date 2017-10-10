//
//  AuthButton.swift
//  TheDocument
//


import UIKit

class AuthButton: UIButton {

    override var isSelected: Bool {
        willSet {
            if newValue {
                self.layer.borderColorFromUIColor = Constants.Theme.authButtonSelectedBorderColor
                self.setTitleColor(Constants.Theme.authButtonSelectedTextColor, for: .normal)
                self.backgroundColor = Constants.Theme.authButtonSelectedBGColor
            } else {
                self.layer.borderColorFromUIColor = Constants.Theme.authButtonNormalBorderColor
                self.setTitleColor(Constants.Theme.authButtonNormalTextColor, for: .normal)
                self.backgroundColor = Constants.Theme.authButtonNormalBGColor
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 3
        self.layer.borderWidth = 2
    }

}
