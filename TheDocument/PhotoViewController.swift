//
//  PhotoViewController.swift
//  TheDocument
//


import Foundation
import UIKit
import Firebase
import FirebaseStorage

class PhotoViewController: BaseViewController {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var skipButton: AuthButton!
    @IBOutlet weak var retakeButton: AuthButton!
    
    var imagePicker: UIImagePickerController!
    var firstRun = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        skipButton.backgroundColor = Constants.Theme.authButtonSelectedBGColor
        skipButton.layer.borderColorFromUIColor = Constants.Theme.authButtonSelectedBorderColor
        retakeButton.backgroundColor = Constants.Theme.authButtonSelectedBGColor
        retakeButton.layer.borderColorFromUIColor = Constants.Theme.authButtonSelectedBorderColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if firstRun {
            initPhotoPicker()
        }
    }
    
    @IBAction func retakePhotoButtonTapped(_ sender: Any) {
        initPhotoPicker()
    }
    
    @IBAction func skipButtonTapped(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: Constants.shouldGetPhotoKey)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        if let image = photoImageView.image, let imageData = UIImageJPEGRepresentation(image, 0.9) {
            
            Storage.storage().reference(withPath: "photos/\(currentUser.uid)").putData(imageData, metadata: nil, completion: { (metadata, error) in
                guard let metadata = metadata else { return }
                log.debug(metadata)
            })
            
            UserDefaults.standard.set(true, forKey: Constants.shouldGetPhotoKey)
            self.dismiss(animated: true, completion: nil)
        } else {
            self.showAlert(message: "\(Constants.Errors.imageSelect.rawValue)")
        }
    }
}

extension PhotoViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    func initPhotoPicker() {
        firstRun = false
        
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
    
    //MARK: - Add image to Library
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        self.showAlert(message: error != nil ? error!.localizedDescription : Constants.Messages.savePhotoSuccess.rawValue)
    }
    
    //MARK: - Done image capture here
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else  {
            self.showAlert(message: Constants.Errors.defaultError.rawValue)
            return
        }
        
        photoImageView.image = image
        currentUser.avatar = image
        
        /*
        if let newImage = resizeImage(image: image, targetSize: CGSize(width: 200, height: 200) ){
            photoImageView.image = newImage
            currentUser.image = newImage
        } else {
            
        }
        */
    }
}
