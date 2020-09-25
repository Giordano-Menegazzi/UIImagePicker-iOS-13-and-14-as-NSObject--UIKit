//
//  AttachmentHandler.swift
//  ETC
//
//  Created by Giordano Menegazzi on 18/03/2019.
//  Copyright © 2019 Autodidact BV. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import PhotosUI

// MARK: - AttachmentHandler object class
/// this class creates a reusable imagePicker controller object
class AttachmentHandler: NSObject
{
    // MARK: - Global File Variables
    static let shared = AttachmentHandler()
    fileprivate weak var currentVC: UIViewController?
    
    /// internal properties
    var retrievedImage: ((UIImage) -> Void)?
    
    /// attachmentType variables
    fileprivate enum AttachmentType: String {
        case camera, video, photoLibrary
    }
    

    
    
    
    
    // MARK: - UIImagePicker Alert Functions
    /// this function shows the actionSheet for the image and camera
    func showAttachmentActionSheet(vc: UIViewController, onDeleteImagePushed: (() -> ())? = nil)
    {
        currentVC = vc
        let alertActionSheet = UIAlertController(title: Language.current.imagePickerAlertTitle, message: Language.current.imagePickerAlertMessage, preferredStyle: .actionSheet)
        
        alertActionSheet.addAction(UIAlertAction(title: Language.current.imagePickerAlertActionCamera, style: .default, handler: { (action: UIAlertAction) in
            self.autorisationStatusCamera(attachmentTypeEnum: .camera)
        }))
        
        alertActionSheet.addAction(UIAlertAction(title: Language.current.imagePickerAlertActionPhotoLibrary, style: .default, handler: { (action: UIAlertAction) in
            self.autorisationStatusPhotoLibrary(attachmentTypeEnum: .photoLibrary)
        }))
        
        alertActionSheet.addAction(UIAlertAction(title: Language.current.imagePickerAlertActionDeleteImage, style: .default, handler: { (action: UIAlertAction) in
            if let deleteImage = onDeleteImagePushed {
                deleteImage()
            }
        }))
        
        alertActionSheet.addAction(UIAlertAction(title: Language.current.alertCancelText, style: .destructive, handler: nil))
        
        createPopOverControllerForIpadWith(actionSheet: alertActionSheet)
        vc.present(alertActionSheet, animated: true, completion: nil)
    }
    
    /// this function creates the popOverController for the ipad
    fileprivate func createPopOverControllerForIpadWith(actionSheet: UIAlertController)
    {
        if let popOverController = actionSheet.popoverPresentationController
        {
            guard let currentVC = currentVC else { return }
            let popOverView = CGRect(x: currentVC.view.bounds.midX, y: currentVC.view.bounds.midY, width: 0, height: 0)
            popOverController.permittedArrowDirections = []
            popOverController.sourceView = currentVC.view
            popOverController.sourceRect = popOverView
        }
    }
    
    
    
    
    
    
    // MARK: - Authorization functions
    /// this checks the autorization status of the photo library acces and handles the case accordingly
    fileprivate func autorisationStatusCamera(attachmentTypeEnum: AttachmentType)
    {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authorizationStatus
        {
        case .authorized:
            handleAuthorized(attachmentTypeEnum: attachmentTypeEnum)
        case .notDetermined:
            handleNotDetermined(attachmentTypeEnum: attachmentTypeEnum)
        case .restricted:
            handleRestrictedOrDenied(attachmentTypeEnum: attachmentTypeEnum)
        case .denied:
            handleRestrictedOrDenied(attachmentTypeEnum: attachmentTypeEnum)
        @unknown default:
            break
        }
    }
    
    /// this checks the autorization status of the photo library acces and handles the case accordingly
    fileprivate func autorisationStatusPhotoLibrary(attachmentTypeEnum: AttachmentType)
    {
        if #available(iOS 14.0, *) {
            handleAutorisationIOS14()
        } else {
            handleAutorisationIOS13(attachmentTypeEnum: attachmentTypeEnum)
        }
    }
    
    /// this function handles the autorization status for iOS 14 and higher
    fileprivate func handleAutorisationIOS14()
    {
        if #available(iOS 14.0, *) {
            guard let currentVC = currentVC else { return }

            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 1
            configuration.filter = .images

            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            currentVC.present(picker, animated: true)
        }
    }
    
    /// this function handles the autorization status for iOS 13
    fileprivate func handleAutorisationIOS13(attachmentTypeEnum: AttachmentType)
    {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authorizationStatus
        {
        case .authorized:
            handleAuthorized(attachmentTypeEnum: attachmentTypeEnum)
        case .notDetermined:
            handleNotDetermined(attachmentTypeEnum: attachmentTypeEnum)
        case .restricted:
            handleRestrictedOrDenied(attachmentTypeEnum: attachmentTypeEnum)
        case .denied:
            handleRestrictedOrDenied(attachmentTypeEnum: attachmentTypeEnum)
        case .limited:
            handleAuthorized(attachmentTypeEnum: attachmentTypeEnum)
        @unknown default:
            handleNotDetermined(attachmentTypeEnum: attachmentTypeEnum)
        }
    }
    
    /// this function handles the authorizationStatus authorized
    fileprivate func handleAuthorized(attachmentTypeEnum: AttachmentType)
    {
        if attachmentTypeEnum == .camera {
            openCamera()
        }
        if attachmentTypeEnum == .photoLibrary {
            openPhotoLibrary()
        }
    }
    
    /// this function handles the authorizationStatus notDetermined
    fileprivate func handleNotDetermined(attachmentTypeEnum: AttachmentType)
    {
        if attachmentTypeEnum == .camera {
            AVCaptureDevice.requestAccess(for: .video) { success in
                if success {
                    self.handleAuthorized(attachmentTypeEnum: attachmentTypeEnum)
                } else {
                    self.handleRestrictedOrDenied(attachmentTypeEnum: attachmentTypeEnum)
                }
            }
        } else if attachmentTypeEnum == .photoLibrary {
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status ==  PHAuthorizationStatus.authorized {
                    self.handleAuthorized(attachmentTypeEnum: attachmentTypeEnum)
                } else {
                    self.handleRestrictedOrDenied(attachmentTypeEnum: attachmentTypeEnum)
                }
            })
        }
    }
    
    /// this function handles the authorizationStatus restricted or denied
    fileprivate func handleRestrictedOrDenied(attachmentTypeEnum: AttachmentType)
    {
        guard let currentVC = currentVC else { return }
        
        let alert = UIAlertController(title: Language.current.imagePickerErrorAlertTitle, message: Language.current.imagePickerErrorAlertMessage, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: Language.current.alertCancelText, style: .cancel)
        let gotoSettingsAction = UIAlertAction(title: Language.current.imagePickerAlertActionGoToSettings, style: .default) { (action) in
            DispatchQueue.main.async {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:])
                }
            }
        }
        
        DispatchQueue.main.async {
            alert.addAction(gotoSettingsAction)
            alert.addAction(cancelAction)
            currentVC.present(alert, animated: true)
        }
    }
}






// MARK: - AttachmentHandler Extension
/// this extension handles the imagePicker delegate functions
extension AttachmentHandler: UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate
{
    // MARK: - Open ImagePicker Functions
    /// this function opens the PHPicker (only on iOS 14)
    @available(iOS 14.0, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult])
    {
        guard let currentVC = currentVC else { return }
        currentVC.dismiss(animated: true)

        if let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self)
        {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
                    guard let self = self, let image = image as? UIImage else { return }
                    self.retrievedImage?(image)
                }
            }
        }
    }
    
    /// this function is used to open the camera from the device
    fileprivate func openCamera()
    {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            guard let currentVC = currentVC else { return }
            
            DispatchQueue.main.async {
                let myPickerController = self.createImagePicker()
                myPickerController.sourceType = .camera
                currentVC.present(myPickerController, animated: true)
            }
        }
    }
    
    /// this function is used to open the photoLibrary from the device
    fileprivate func openPhotoLibrary()
    {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            guard let currentVC = currentVC else { return }
            
            DispatchQueue.main.async {
                let myPickerController = self.createImagePicker()
                myPickerController.sourceType = .photoLibrary
                currentVC.present(myPickerController, animated: true)
            }
        }
    }
    
    /// this function creates the image picker and sets the delegate
    fileprivate func createImagePicker() -> UIImagePickerController
    {
        let myPickerController = UIImagePickerController()
        
        myPickerController.delegate = self
        myPickerController.allowsEditing = true
        
        return myPickerController
    }
    
    
    
    
    
    
    // MARK: - Close ImagePicker Functions (UIImagePickerControllerDelegate)
    /// this function dissmisses the imagepicker if its cancelled
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        guard let currentVC = currentVC else { return }
        currentVC.dismiss(animated: true)
    }
    
    /// this function stores the picked image
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        guard let currentVC = currentVC else { return }

        if let image = info[.editedImage] as? UIImage {
            retrievedImage?(image)
        } else if let image = info[.originalImage] as? UIImage {
            retrievedImage?(image)
        }
        currentVC.dismiss(animated: true)
    }
}
