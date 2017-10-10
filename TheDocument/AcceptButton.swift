//
//  AcceptButton.swift
//  TheDocument
//


import UIKit

class AcceptButton: UIButton {
    
    typealias TapClosure = (AcceptButton) -> ()
    
    var didTouchUpInside: TapClosure? {
        didSet {
            if didTouchUpInside != nil {
                addTarget(self, action: #selector(didTouchUpInside(_:)), for: .touchUpInside)
            } else {
                removeTarget(self, action: #selector(didTouchUpInside(_:)), for: .touchUpInside)
            }
        }
    }
    
    // MARK: - Actions
    @objc func didTouchUpInside(_ sender: UIButton) {
        if let handler = didTouchUpInside {
            handler(self)
        }
    }

    override var isSelected: Bool {
        willSet {
            if newValue {
                self.layer.borderColorFromUIColor = Constants.Theme.authButtonSelectedBorderColor
            } else {
                self.layer.borderColorFromUIColor = Constants.Theme.authButtonNormalBorderColor
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = Constants.Theme.authButtonSelectedBGColor
        self.setTitleColor(Constants.Theme.authButtonSelectedTextColor, for: .normal)
        self.layer.cornerRadius = 3
        self.layer.borderWidth = 1
    }

}
