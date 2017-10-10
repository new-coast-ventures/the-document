//
//  SettingsViewController.swift
//  TheDocument
//

import Foundation
import UIKit
import Firebase
import FirebaseStorage

class SettingsViewController: BaseViewController {
    
    @IBOutlet weak var editPhoto: UIImageView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var postcodeTextfield: InputField!
    @IBOutlet weak var nameTextField: InputField!
    @IBOutlet weak var emailTextField: InputField!
    @IBOutlet weak var phoneTextField: InputField!
    @IBOutlet weak var saveButton: UIButton!
    
    var imagePicker: UIImagePickerController!
    var newImageSet:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        editPhoto.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(takePhoto)))
        photoImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(takePhoto)))
        
        if let imageData = downloadedImages["\(currentUser.uid)"] {
            setPhotoWithData(imageData: imageData)
        } else {
            appDelegate.downloadImageFor(id: "\(currentUser.uid)", section: "photos"){[weak self] success in
                guard success, let sSelf = self,  let imageData = downloadedImages["\(currentUser.uid)"]  else { return }
                sSelf.setPhotoWithData(imageData: imageData)
            }
        }
        
        nameTextField.text = currentUser.name
        emailTextField.text = currentUser.email
        phoneTextField.text = currentUser.phone
        postcodeTextfield.text = currentUser.postcode
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideKeyboard)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.hideToolbar)"), object: nil)
    }
    
    deinit {
    }
    
    @objc func takePhoto() {
        let pickerView = UIAlertController(title: "Set Your Profile Picture", message: nil, preferredStyle: .alert)
        
        let libraryAction = UIAlertAction(title: "Choose From Library", style: .default) { (alertAction) in
            self.imagePicker = imagePickerVC(camera: false, delegate: self)
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        
        let cameraAction = UIAlertAction(title: "Take Photo", style: .default) { (alertAction) in
            self.imagePicker = imagePickerVC(camera: true, delegate: self)
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        
        pickerView.addAction(libraryAction)
        pickerView.addAction(cameraAction)
        
        self.present(pickerView, animated: true, completion: nil)
    }
    
    func setPhotoWithData(imageData:Data) {
        DispatchQueue.main.async {
            self.photoImageView.image = UIImage(data: imageData)
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton? = nil) {
        self.startActivityIndicator()
        
        let newName = nameTextField.text ?? currentUser.name
        let newPostCode = postcodeTextfield.text ?? currentUser.postcode
        
        var newPhone = currentUser.phone
        if let newPhoneText = phoneTextField.text {
            // Format the phone number as digits only before sending to the server
            newPhone = newPhoneText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        }
        
        API().editInfo(newName: newName, newPostCode: newPostCode, newPhone: newPhone) { [weak self] success in
            if success {
                currentUser.name = newName
                self?.uploadImage()
                self?.stopActivityIndicator()
                self?.navigationController?.popViewController(animated: true)
            } else {
                self?.showAlert(message: "\(Constants.Errors.defaultError.rawValue)")
            }
        }
    }
    
    func uploadImage() {
        if newImageSet, let image = photoImageView.image, let imageData = UIImageJPEGRepresentation(image, 0.9) {
            downloadedImages["\(currentUser.uid)"] = imageData
            
            Storage.storage().reference(withPath: "photos/\(currentUser.uid)").putData(imageData, metadata: nil, completion: { (metadata, error) in
                guard let metadata = metadata else { return }
                print("Metadata: ", metadata)
            })
        }
    }
    
    //MARK: Helpers
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
}

extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
                self.photoImageView.image = newImage
                currentUser.image = newImage
            }
        } else {
            DispatchQueue.main.async {
                self.photoImageView.image = image
                currentUser.image = image
            }
        }
        
        self.newImageSet = true
    }
}

extension SettingsViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == phoneTextField else { return true }
        
        let newNumber  = NSString(string: textField.text ?? "").replacingCharacters(in: range, with: string)
        textField.text = formattedNumber(number: newNumber)
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        switch textField {
            case nameTextField:
                phoneTextField.becomeFirstResponder()
            case phoneTextField:
                postcodeTextfield.becomeFirstResponder()
            case postcodeTextfield:
                saveButtonTapped()
                break;
            default: break
        }
        return true
    }
    
    private func formattedNumber(number: String) -> String {
        let cleanPhoneNumber = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let mask = "(XXX) XXX XXXX"
        
        var result = ""
        var index = cleanPhoneNumber.startIndex
        for ch in mask.characters {
            if index == cleanPhoneNumber.endIndex {
                break
            }
            if ch == "X" {
                result.append(cleanPhoneNumber[index])
                index = cleanPhoneNumber.index(after: index)
            } else {
                result.append(ch)
            }
        }
        return result
    }
}

