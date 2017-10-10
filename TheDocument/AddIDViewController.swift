//
//  AddIDViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 6/30/17.
//  Copyright © 2017 Mruvka. All rights reserved.
//

import UIKit

class AddIDViewController: BaseViewController {
    
    var imagePicker: UIImagePickerController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.hideToolbar)"), object: nil)
    }
    
    deinit {
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func launchCamera(_ sender: Any) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
}

extension AddIDViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        self.showAlert(message: error != nil ? error!.localizedDescription : Constants.Messages.savePhotoSuccess.rawValue)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        guard let _ = info[UIImagePickerControllerOriginalImage] as? UIImage else  {
            self.showAlert(message: Constants.Errors.defaultError.rawValue)
            return
        }
        
        if let selectBankTVC = self.storyboard?.instantiateViewController(withIdentifier: "SelectBankTVC") as? SelectBankTableViewController {
            self.navigationController?.pushViewController(selectBankTVC, animated: true)
        }
    }
}
