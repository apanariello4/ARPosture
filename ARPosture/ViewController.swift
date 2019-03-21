//
//  ViewController.swift
//  ARPosture
//
//  Created by admin on 22/02/19.
//  Copyright © 2019 a.panariello. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController,ARSessionDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var inclinationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var absoluteTiltLabel: UILabel!
    @IBOutlet weak var relativeTiltLabel: UILabel!
    @IBOutlet weak var cameraInclinationLabel: UILabel!
    @IBOutlet weak var meanInclinationLabel: UILabel!
    @IBOutlet weak var postureStatusLabel: UILabel!
    
    var counter = 0
    weak var timer: Timer?
    
    var mean: Float = 0
    
    var sensibility = UserDefaults.standard.integer(forKey: "sensibility")
    
    var sensibilityTime = UserDefaults.standard.integer(forKey: "sensibilityTime")
    
    var isNodeVisible: Bool = false
    
    var meanCounter: Float = 1
    
    var postureCounter: Int = 1
    
    var alertFlag: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard ARFaceTrackingConfiguration.isSupported else {fatalError()}
        
        sceneView.delegate = self
        
        sceneView.preferredFramesPerSecond = UserDefaults.standard.integer(forKey: "fps")
        
        //sceneView.showsStatistics = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true

        sceneView.session.run(configuration)
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0,repeats: true) {
                theTimer in
                self.update()
            }
        }
        
     
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
        
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }
}

let alert = UIAlertController(title: "Attenzione", message: "Stai utilizzando lo smartphone con un postura scorretta da troppo tempo.\nUtilizza una postura migliore o fai una pausa.", preferredStyle: .alert)

var currentFaceAnchor: ARFaceAnchor?

var headNode: SCNNode?

// Load an asset to provide visual content for the anchor.
var rightEyeNode = SCNReferenceNode(named: "coordinateOrigin")
var leftEyeNode = SCNReferenceNode(named: "coordinateOrigin")


extension ViewController: ARSCNViewDelegate {
    
   
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // This class adds AR content only for face anchors.
        guard anchor is ARFaceAnchor else { return nil }
        headNode = SCNNode()
        
        // Add content for eye tracking in iOS 12.
        self.addEyeTransformNodes()
        
        // Provide the node to ARKit for keeping in sync with the face anchor.
        return headNode
    }
    
    func addEyeTransformNodes() {
        guard #available(iOS 12.0, *), let anchorNode = headNode else { return }
        
        // Scale down the coordinate axis visualizations for eyes.
        rightEyeNode.simdPivot = float4x4(diagonal: float4(3, 3, 3, 1))
        leftEyeNode.simdPivot = float4x4(diagonal: float4(3, 3, 3, 1))
       
        anchorNode.addChildNode(rightEyeNode)
        anchorNode.addChildNode(leftEyeNode)

    }
 

    func update(){
       
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            
            self.postureCounter -= 20
            
        }))
        
        rightEyeNode.isHidden = !(UserDefaults.standard.bool(forKey: "showAxis"))
        leftEyeNode.isHidden = !(UserDefaults.standard.bool(forKey: "showAxis"))
       
        sceneView.preferredFramesPerSecond = UserDefaults.standard.integer(forKey: "fps")
        
        let pointOfView = sceneView.pointOfView
        isNodeVisible = sceneView.isNode(rightEyeNode, insideFrustumOf: pointOfView!)
        
        
        if ((headNode?.simdWorldTransform != nil) && sceneView.pointOfView?.simdWorldTransform != nil){
            if (isNodeVisible == true){
            
            let faceOrientation: simd_quatf = simd_quatf((headNode?.simdWorldTransform)!)
            let cameraOrientation: simd_quatf = simd_quatf((sceneView.pointOfView?.simdWorldTransform)!)
            let cameraObject = sceneView.session.currentFrame!.camera
            let deltaOrientation: simd_quatf = faceOrientation.inverse * cameraOrientation
        
            let faceTilt = headNode!.eulerAngles.z // absolute head tilt (roll)
            let faceInclination = headNode!.eulerAngles.x // absolute head inclination (pitch)
                
            let relativeAxis = deltaOrientation.axis * deltaOrientation.angle // we get the inclination of every coordinate in radians
    
            let inclinationDegrees = roundDec((relativeAxis.x * (180/Float.pi)))
            let relativeTilt = roundDec((relativeAxis.z * (180/Float.pi)))
            let cameraPosition = (cameraObject.eulerAngles) * (180/Float.pi)
            //x represents pitch in degrees (up and down),  z is the roll (right and left), y is the yaw (turns on itself)
            let absoluteCameraTiltX = round(cameraPosition.x)
            
            let absoluteHeadTilt = roundDec((faceTilt * (180/Float.pi)))
                
            let absoluteHeadInclination = roundDec((faceInclination * (180/Float.pi)))
                
            absoluteTiltLabel.text = "Tilt abs: \(String(absoluteHeadTilt))°"
            
            relativeTiltLabel.text = "Tilt rel: \(String(round(relativeTilt)))°"
            
            inclinationLabel.text = "Incl. rel: \(String(inclinationDegrees))° abs: \(String(absoluteHeadInclination))"
            
            cameraInclinationLabel.text = "Cam X: \(String(absoluteCameraTiltX))°"
            
                
                if (absoluteCameraTiltX < Float(10 + 1 * sensibility) || absoluteCameraTiltX > Float(40 - 5 * sensibility)) {
                    postureStatusLabel.textColor = UIColor.red
                    postureStatusLabel.text = "Bad"
                    postureCounter += 2
                }else if(inclinationDegrees > Float(15 - 3 * sensibility) || inclinationDegrees < 0){
                    postureStatusLabel.textColor = UIColor.orange
                    postureStatusLabel.text = "Bad"
                    postureCounter += 1
                }else{
                    postureStatusLabel.textColor = UIColor.green
                    postureStatusLabel.text = "Ok"
                    postureCounter = 0
                }
                if (sensibilityTime == 0){
                    if (postureCounter > 30){
                        self.present(alert, animated: true, completion: nil)
                        postureCounter -= 15
                    }
                }else{
                if (postureCounter > 120 * sensibilityTime){
                    self.present(alert, animated: true, completion: nil)
                    postureCounter -= 30
                    }
                }
                
                mean = roundDec((mean*meanCounter + inclinationDegrees)/(meanCounter + 1))
                meanCounter += 1
                meanInclinationLabel.text = "Media inclinazione: \(mean) °"
                
            }else{
                absoluteTiltLabel.text = "Tilt abs: 0.0°"
                
                relativeTiltLabel.text = "Tilt rel: 0.0°"
                
                inclinationLabel.text = "Incl. rel: 0.0° abs: 0.0°"
                
                cameraInclinationLabel.text = "Cam X: 0.0°"
                
                postureStatusLabel.text = ""
                
                meanInclinationLabel.text = "Media inclinazione: "
                
                print("Volto fuori dalla scena")
                
            }
           
            
        }else{
            print("Volto non rilevato")
        }
        
        eyeDistance()

    }
    
    
    func eyeDistance(){
        
        let leftEyeDistance = leftEyeNode.worldPosition - SCNVector3Zero
        let rightEyeDistance = rightEyeNode.worldPosition - SCNVector3Zero
        
        let averageDistance = (leftEyeDistance.length() + rightEyeDistance.length())/2
        let averageDistanceCm = Int(round(averageDistance * 100)) - 7
        
        if (averageDistanceCm > 15 && isNodeVisible == true){
            distanceLabel.text = "Distanza: \(String(averageDistanceCm)) cm"
        }else if (averageDistanceCm <= 15){
            distanceLabel.text = "Troppo vicino alla camera"
        }else if (isNodeVisible == false){
            distanceLabel.text = "Volto non rilevato"
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard #available(iOS 12.0, *), let faceAnchor = anchor as? ARFaceAnchor
            else { return }
        rightEyeNode.simdTransform = faceAnchor.rightEyeTransform
        leftEyeNode.simdTransform = faceAnchor.leftEyeTransform
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        currentFaceAnchor = faceAnchor
        
    }
    
}

