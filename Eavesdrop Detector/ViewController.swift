//
//  ViewController.swift
//  Eavesdrop Detector
//
//  Created by David Darling on 12/13/19.
//  Copyright © 2019 David Darling. All rights reserved.
//

import UIKit
import Alamofire
import AVFoundation
import CoreLocation

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var scanning = false
    var scanHeading: Double = 0
    var imagePicker: UIImagePickerController!
    var sensitiveViews = [UIView]()
    var imageView: UIImageView!
    var locationManager: CLLocationManager!
    var currHeading: Double = 0
    var scanButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
        
        imageView = (self.view.viewWithTag(4) as! UIImageView)
        let accountTextLabel = self.view.viewWithTag(1) as! UILabel
        let accountBalanceLabel = self.view.viewWithTag(2) as! UILabel
        
        self.scanButton = (self.view.viewWithTag(3) as! UIButton)
        self.scanButton.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        self.scanButton.setTitle("Start Scan", for: .normal)
        
        sensitiveViews.append(accountTextLabel)
        sensitiveViews.append(accountBalanceLabel)
        
        takePhotoSecret()
    }
    
    func uploadPhoto(image: UIImage) {
        let jpeg = image.jpegData(compressionQuality: 0.2)
        var scanFlag = scanning
        if abs(currHeading - scanHeading) < 10.0 {
            scanFlag = false
        }
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(jpeg!, withName: "image", fileName: "image.jpg", mimeType: "image/jpeg")
            multipartFormData.append(Data((scanFlag ? "True" : "False").utf8), withName: "scanning")
        }, to: "http://192.168.1.12:8000/processing/detect")
            .responseJSON { response in
                debugPrint(response)
                self.takePhotoSecret()
            }
    }
    
    func takePhotoSecret() {
        if imagePicker != nil {
            return
        }
        
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.cameraDevice = .front
        imagePicker.showsCameraControls = false
        imagePicker.cameraFlashMode = .off
        addChild(imagePicker)
        imagePicker.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(imagePicker.view)
        imagePicker.didMove(toParent: self)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.imagePicker.takePicture()
        }
    
    }
    
    @objc func buttonClicked(_ sender: UIButton) {
        scanning = !scanning
        if scanning {
            scanHeading = currHeading
            self.scanButton.setTitle("Scanning...", for: .normal)
        } else {
            self.scanButton.setTitle("Start Scan", for: .normal)
        }
        
        
    }
    
    func hideSensitiveElements(sensitiveViews: Array<UIView>) {
        
        for item in sensitiveViews {
            let blur = UIBlurEffect(style: .extraLight)
            let blurView = UIVisualEffectView(effect: blur)
            blurView.tag = 0
            blurView.frame = item.bounds
            item.addSubview(blurView)
        }
    }
    
    func showSensitiveElements(sensitiveViews: Array<UIView>) {
        for label in sensitiveViews {
            let blurView = label.viewWithTag(0)
            blurView?.removeFromSuperview()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Cancel Delegate")
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        imagePicker.dismiss(animated: false, completion: nil)
        imagePicker.view.removeFromSuperview()
        imagePicker.removeFromParent()
        imagePicker = nil
        
        uploadPhoto(image: (info[.originalImage] as! UIImage))
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.currHeading = newHeading.magneticHeading
    }
}
