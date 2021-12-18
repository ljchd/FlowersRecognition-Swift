//
//  ViewController.swift
//  Flowers
//
//  Created by PID-PRODUCTENGINEER-EO2180 on 10/11/21.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var cameraUnavailableLabel: UILabel!
    @IBOutlet weak var resumeButton: UIButton!
    @IBOutlet weak var bottomSheetView: CurvedView!
    
    @IBOutlet weak var bottomSheetViewBottomSpace: NSLayoutConstraint!
    @IBOutlet weak var bottomSheetStateImageView: UIImageView!
    
    private let animationDuration = 0.5
    private let collapseTransitionThreshold: CGFloat = -40.0
    private let expandThransitionThreshold: CGFloat = 40.0
    private let delayBetweenInferencesMs: Double = 1000
    
    private let flowerManager = FlowerManager()
    private var detectedFlower: Flower!
    
    private var result: Result?
    private var flowers: [String] = [String]()
    private var initialBottomSpace: CGFloat = 0.0
    private var previousInferenceTimeMs: TimeInterval = Date.distantPast.timeIntervalSince1970 * 1000
    
    private lazy var cameraCapture = CameraFeedManager(previewView: previewView)
    
    private var modelDataHandler: ModelDataHandler? =
    ModelDataHandler(modelFileInfo: MobileNet.modelInfo, labelsFileInfo: MobileNet.labelsInfo)
    
    private var inferenceViewController: InferenceViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard modelDataHandler != nil else {
            fatalError("Model set up failed")
        }
        
#if targetEnvironment(simulator)
        previewView.shouldUseClipboardImage = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(classifyPasteboardImage),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
#endif
        cameraCapture.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavigationBar(animated: animated)
        
#if !targetEnvironment(simulator)
        cameraCapture.checkCameraConfigurationAndStartSession()
#endif
    }
    
#if !targetEnvironment(simulator)
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraCapture.stopSession()
        showNavigationBar(animated: animated)
    }
#endif
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func presentUnableToResumeSessionAlert() {
        let alert = UIAlertController(
            title: "Unable to Resume Session",
            message: "There was an error while attempting to resume session.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "EMBED" {
            
            guard let tempModelDataHandler = modelDataHandler else {
                return
            }
            inferenceViewController = segue.destination as? InferenceViewController
            inferenceViewController?.wantedInputHeight = tempModelDataHandler.inputHeight
            inferenceViewController?.wantedInputWidth = tempModelDataHandler.inputWidth
            inferenceViewController?.maxResults = tempModelDataHandler.resultCount
            inferenceViewController?.threadCountLimit = tempModelDataHandler.threadCountLimit
            inferenceViewController?.delegate = self
            
        }
    }
    
    @objc func classifyPasteboardImage() {
        guard let image = UIPasteboard.general.images?.first else {
            return
        }
        
        guard let buffer = CVImageBuffer.buffer(from: image) else {
            return
        }
        
        previewView.image = image
        
        DispatchQueue.global().async {
            self.didOutput(pixelBuffer: buffer)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension ViewController: InferenceViewControllerDelegate {
    
    func didChangeThreadCount(to count: Int) {
        if modelDataHandler?.threadCount == count { return }
        modelDataHandler = ModelDataHandler(
            modelFileInfo: MobileNet.modelInfo,
            labelsFileInfo: MobileNet.labelsInfo,
            threadCount: count
        )
    }
}

extension ViewController: CameraFeedManagerDelegate {
    
    func didOutput(pixelBuffer: CVPixelBuffer) {
        let currentTimeMs = Date().timeIntervalSince1970 * 1000
        guard (currentTimeMs - previousInferenceTimeMs) >= delayBetweenInferencesMs else { return }
        previousInferenceTimeMs = currentTimeMs
        
        result = modelDataHandler?.runModel(onFrame: pixelBuffer)
        
        let flower = (result?.inferences[0].label)!
        
        let match = flowers.filter{ $0 ==  flower}
        
        if match.count > 1 {
            flowers.removeAll()
            detectedFlower = flowerManager.getFlowerDetails(flowerName: flower)
            if detectedFlower.name != "" {
                DispatchQueue.main.async {
                    self.goToDetails()
                }
            }
        } else {
            flowers.append((result?.inferences[0].label)!)
        }
        
        DispatchQueue.main.async {
            let resolution = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            self.inferenceViewController?.inferenceResult = self.result
            self.inferenceViewController?.resolution = resolution
            self.inferenceViewController?.tableView.reloadData()
        }
    }
    
    func sessionWasInterrupted(canResumeManually resumeManually: Bool) {
        
        // Updates the UI when session is interupted.
        if resumeManually {
            self.resumeButton.isHidden = false
        } else {
            self.cameraUnavailableLabel.isHidden = false
        }
    }
    
    func sessionInterruptionEnded() {
        if !self.cameraUnavailableLabel.isHidden {
            self.cameraUnavailableLabel.isHidden = true
        }
        
        if !self.resumeButton.isHidden {
            self.resumeButton.isHidden = true
        }
    }
    
    func sessionRunTimeErrorOccured() {
        self.resumeButton.isHidden = false
        previewView.shouldUseClipboardImage = true
    }
    
    func presentCameraPermissionsDeniedAlert() {
        let alertController = UIAlertController(title: "Camera Permissions Denied", message: "Camera permissions have been denied for this app. You can change this by going to Settings", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        
        present(alertController, animated: true, completion: nil)
        
        previewView.shouldUseClipboardImage = true
    }
    
    func presentVideoConfigurationErrorAlert() {
        let alert = UIAlertController(title: "Camera Configuration Failed", message: "There was an error while configuring camera.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true)
        previewView.shouldUseClipboardImage = true
    }
    
    func goToDetails() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "FlowerDetailsViewController") as? FlowerDetailsViewController {
            vc.flowerImage = detectedFlower.name
            vc.flowerTitle = detectedFlower.name
            vc.flowerDescription = detectedFlower.description
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension UIViewController {
    func hideNavigationBar(animated: Bool){
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
    }
    
    func showNavigationBar(animated: Bool) {
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
}
