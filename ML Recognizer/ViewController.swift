//
//  ViewController.swift
//  ML Recognizer
//
//  Created by Roman on 10/24/17.
//  Copyright © 2017 Roman Rudavskiy. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var resultLbl: UILabel!
    
    let mlModelTextField = UITextField()
    let mlModels = ["SqueezeNet, 5mb", "MobileNet, 17.1mb", "Places205-GoogLeNet, 24.8mb"]
    var modelName:String = ""
    
    var pickerModel = MLModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mlModelTextField.text = mlModels[0]
        
        createPicker()
        
        //setup the result label
        resultLbl.widthAnchor.constraint(equalToConstant: (view.frame.width) * 0.99).isActive = true
        resultLbl.font = UIFont(name: "HelveticaNeue-Bold", size: 14)
        resultLbl.textColor = UIColor.blue
        resultLbl.numberOfLines = 1
        resultLbl.adjustsFontSizeToFitWidth = true
        
        //Start up the camera on device
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label:"videoQ"))
        captureSession.addOutput(dataOutput)
        
    }
    
    func createPicker() {
        let picker = pickerView!
        
        picker.widthAnchor.constraint(equalToConstant: (view.frame.width) * 0.7).isActive = true
        
        picker.dataSource = self
        picker.delegate = self
        
        mlModelTextField.inputView = picker
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 14)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = mlModels[row]
        pickerLabel?.textColor = UIColor.blue
        
        return pickerLabel!
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return mlModels.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return mlModels[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        
        mlModelTextField.text = mlModels[row]
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer:CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        DispatchQueue.main.async {
            if self.mlModelTextField.text == "MobileNet, 17.1mb" {
                self.pickerModel =  MobileNet().model
                self.modelName = "MobileNet"
            } else if self.mlModelTextField.text == "SqueezeNet, 5mb" {
                self.pickerModel = SqueezeNet().model
                self.modelName = "SqueezeNet"
            } else if self.mlModelTextField.text == "Places205-GoogLeNet, 24.8mb" {
                self.pickerModel = GoogLeNetPlaces().model
                self.modelName = "Places205-GoogLeNet"
            }
        }
        
        let mlModel = pickerModel
        
        guard let model = try? VNCoreMLModel(for: mlModel) else {return}
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            //perhaps need to check the error
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
            
            guard let firstResult =  results.first else {return}
            
            print(firstResult.identifier, firstResult.confidence)
            
            DispatchQueue.main.async(execute: {
                self.resultLbl.text = "\(self.modelName): \(firstResult.identifier) \(String(format: "%.2f", firstResult.confidence*100))%"
            })
            
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
    }//captureOutput
    
}//class

