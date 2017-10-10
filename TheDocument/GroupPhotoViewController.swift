//
//  GroupPhotoViewController.swift
//  TheDocument
//

import Foundation
import UIKit
import Firebase

class GroupPhotoViewController: BaseViewController {
    
    @IBOutlet weak var descriptionTextfield: InputField!
    @IBOutlet weak var nameTextField: InputField!
    @IBOutlet weak var formatPicker: UIPickerView!
    @IBOutlet weak var groupPhotoImageView: UIImageView!
    @IBOutlet weak var groupPhotoTextField: InputField!
    
    var approvedChallenges: [String] = [String]()
    var imagePicker: UIImagePickerController!
    var newImageSet:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.delegate = self
        descriptionTextfield.delegate = self
        descriptionTextfield.placeholder = "Challenge Type (tennis, checkers, etc...)"
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideKeyboard)))
        
        groupPhotoImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(takePhoto)))

        approvedChallenges = ["All Challenges", "Cornhole", "Ladder Toss", "Washers", "Frisbee Golf", "Ring Toss", "Pop-a-Shot", "Pong", "Flip Cup", "Spinning", "Running", "Circuit Training", "Weight Lifting", "Golf", "Tennis", "Basketball", "Bowling", "Skiing", "Video Game", "Checkers", "Chess", "Backgammon"].sorted()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.hideToolbar)"), object: nil)
    }
    
    deinit {
        view.gestureRecognizers?.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func takePhoto() {
        let pickerView = UIAlertController(title: "Set Group Photo", message: nil, preferredStyle: .alert)
        
        let libraryAction = UIAlertAction(title: "Choose From Library", style: .default) { (alertAction) in
            self.imagePicker = imagePickerVC(camera: false, delegate: self)
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (cancelAction) in
        }
        
        let cameraAction = UIAlertAction(title: "Take Photo", style: .default) { (alertAction) in
            self.imagePicker = imagePickerVC(camera: true, delegate: self)
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        
        pickerView.addAction(libraryAction)
        pickerView.addAction(cameraAction)
        pickerView.addAction(cancelAction)
        
        self.present(pickerView, animated: true, completion: nil)
    }
    
    func setPhotoWithData(imageData:Data) {
        DispatchQueue.main.async {
            self.groupPhotoImageView.image = UIImage(data: imageData)
        }
    }

    @IBAction func doneButtonTapped(_ sender: UIButton? = nil) {
        
        if let name = nameTextField.text, let desc = descriptionTextfield.text, !name.isEmpty {
            self.startActivityIndicator()

            var imageData: Data? = nil
            if let image = groupPhotoImageView.image {
                imageData = UIImageJPEGRepresentation(image, 0.9)
            }
            
            API().addGroup(name: name, desc: desc, imgData: imageData) { success in
                self.stopActivityIndicator()
                if success {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.groupsRefresh)"), object: nil)
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }
                } else {
                    self.showAlert(message: "\(Constants.Errors.defaultError.rawValue)")
                }
            }
        } else {
            self.showAlert(message: "\(Constants.Errors.groupCreate.rawValue)")
        }
    }
    
    @objc func hideKeyboard() {
        formatPicker.isHidden = true
        view.endEditing(true)
    }
}

extension GroupPhotoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        self.showAlert(message: error != nil ? error!.localizedDescription : Constants.Messages.savePhotoSuccess.rawValue)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else  {
            
            self.showAlert(message: Constants.Errors.defaultError.rawValue)
            return
        }
        
        if let newImage = resizeImage(image: image, targetSize: CGSize(width: 400, height: 400) ){
            DispatchQueue.main.async {
                self.groupPhotoImageView.image = newImage
            }
        } else {
            DispatchQueue.main.async {
                self.groupPhotoImageView.image = image
            }
        }
        
        self.groupPhotoImageView.layer.cornerRadius = self.groupPhotoImageView.frame.height/2
        self.groupPhotoImageView.layer.borderWidth = 0
        self.groupPhotoImageView.layer.masksToBounds = true
        
        self.groupPhotoTextField.text = "Edit Photo"
        self.newImageSet = true
    }
}

extension GroupPhotoViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return approvedChallenges.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return approvedChallenges[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.descriptionTextfield.text = approvedChallenges[row]
    }
}

extension GroupPhotoViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        formatPicker.isHidden = true
        if textField == descriptionTextfield {
            //view.endEditing(true)
            //formatPicker.isHidden = false
            //return false
        } else if textField == groupPhotoTextField {
            view.endEditing(true)
            self.takePhoto()
            return false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        switch textField {
            case nameTextField:
                descriptionTextfield.becomeFirstResponder()
            case descriptionTextfield:
                doneButtonTapped()
            default: break
        }
        return true
    }
}
