//
//  CommentTableViewCell.swift
//  TheDocument
//
//  Created by Scott Kacyn on 7/18/17.
//  Copyright © 2017 Mruvka. All rights reserved.
//

import UIKit

class CommentTableViewCell: UITableViewCell {

    @IBOutlet weak var authorImageView: UIImageView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var commentContainerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        cleanup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cleanup()
    }
    
    func cleanup() {
        authorLabel.text = ""
        commentLabel.text = ""
        authorImageView.image = UIImage()
        
        commentContainerView.layer.cornerRadius = 3.0
        commentContainerView.layer.masksToBounds = true
        commentContainerView.layer.borderWidth = 0
    }
    
    func setImage(imgData:Data) {
        DispatchQueue.main.async {
            self.authorImageView.image = UIImage(data: imgData)
            self.authorImageView.layer.cornerRadius = self.authorImageView.frame.size.height / 2.0
            self.authorImageView.layer.masksToBounds = true
            self.authorImageView.layer.borderWidth = 0
            self.authorImageView.isHidden = false
        }
    }
}
