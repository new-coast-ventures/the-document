//
//  TabButton.swift
//  TheDocument
//


import UIKit

class TabButton: UIButton {
    
    var lineView:UIView = UIView()
    
    var isChecked: Bool = false {
        didSet{
            lineView.backgroundColor = isChecked ? Constants.Theme.tabButtonSelectesTextColor :  Constants.Theme.separatorColor
            setTitleColor( isChecked ? Constants.Theme.tabButtonSelectesTextColor : Constants.Theme.tabButtonTextColor, for: .normal)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
       
        self.isChecked = false
    
        lineView = UIView()
        self.titleLabel?.font = UIFont(name: Constants.Theme.tabButtonFontName, size: Constants.Theme.tabButtonFontSize)
        
        lineView.frame = CGRect(x: 0, y: self.frame.size.height - 2, width: self.frame.size.width, height: 2)
        lineView.backgroundColor = isSelected ? Constants.Theme.tabButtonSelectesTextColor :  Constants.Theme.separatorColor
        self.addSubview(lineView)
    }
    
}
