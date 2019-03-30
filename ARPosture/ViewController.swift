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
    @IBOutlet weak var balanceLabel: UILabel!
    
    weak var timer: Timer?
    
    var mean: Float = 0
    
    var isNodeVisible: Bool = false
    
    var meanCounter: Float = 1
    
    var badPostureCounter: Double = 1
    
    var goodPostureCounter: Double = 1
    
    var postureCounter: Double = 1
    
    var alertCounter: Double = 1
    
    var alertFlag: Bool = false
    
    var alertFlagBalance: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard ARFaceTrackingConfiguration.isSupported else {fatalError()}
        
        sceneView.delegate = self
        
        sceneView.preferredFramesPerSecond = UserDefaults.standard.integer(forKey: "fps") //set fps from userdefaults value
        
        //sceneView.showsStatistics = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true

        sceneView.session.run(configuration) //starts the session
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0,repeats: true) { //once every second we call the update function
                theTimer in
                self.update()
            }
        }
        
     
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
        
        if timer != nil {
            timer!.invalidate() //changing view will stop the timer, preventing multiple istances
            timer = nil
        }
    }
}


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
       
        //add childnodes to anchornode
        anchorNode.addChildNode(rightEyeNode)
        anchorNode.addChildNode(leftEyeNode)

    }
 

    func update(){
        
        let sensibility = UserDefaults.standard.integer(forKey: "sensibility")
        
        let sensibilityTime = UserDefaults.standard.double(forKey: "sensibilityTime")
        
        let alert = UIAlertController(title: "Attenzione", message: "Stai utilizzando lo smartphone con un postura scorretta da troppo tempo.\nUtilizza una postura migliore o fai una pausa.", preferredStyle: .alert)
        let alertBalance = UIAlertController(title: "Attenzione", message: "Negli ultimi due minuti c'è stata una prevalenza di postura scorretta.\nUtilizza una postura migliore o fai una pausa.", preferredStyle: .alert)
       
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.alertCounter -= 20
            self.alertFlag = true
        }))
        alertBalance.addAction(UIAlertAction(title: "OK", style: .default, handler:{ action in
            self.alertFlagBalance = true
        }))
        
        rightEyeNode.isHidden = !(UserDefaults.standard.bool(forKey: "showAxis"))
        leftEyeNode.isHidden = !(UserDefaults.standard.bool(forKey: "showAxis"))
       
        sceneView.preferredFramesPerSecond = UserDefaults.standard.integer(forKey: "fps")
        
        let pointOfView = sceneView.pointOfView
        isNodeVisible = sceneView.isNode(rightEyeNode, insideFrustumOf: pointOfView!) // used to define if the face is in the scene
        
        
        if ((headNode?.simdWorldTransform != nil) && sceneView.pointOfView?.simdWorldTransform != nil){
            if (isNodeVisible == true){
            
            let faceOrientation: simd_quatf = simd_quatf((headNode?.simdWorldTransform)!)
            let cameraOrientation: simd_quatf = simd_quatf((sceneView.pointOfView?.simdWorldTransform)!)
            let cameraObject = sceneView.session.currentFrame!.camera
            let deltaOrientation: simd_quatf = faceOrientation.inverse * cameraOrientation
        
            let faceTilt = headNode!.eulerAngles.z // absolute head tilt (roll)
            let faceInclination = headNode!.eulerAngles.x//eulerAngles.x // absolute head inclination (pitch)
            
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
            
            cameraInclinationLabel.text = "Incl. cam.: \(String(Int(absoluteCameraTiltX)))°"
            
            
                postureCounter += 1
                
                if(absoluteHeadInclination > Float(20 - 3 * sensibility) || absoluteHeadInclination < -2){
                    postureStatusLabel.textColor = UIColor.red
                    postureStatusLabel.text = "Bad"
                    
                    badPostureCounter += 1
                    alertCounter += 1
                }else{
                    postureStatusLabel.textColor = UIColor.green
                    postureStatusLabel.text = "Ok"
                    
                    goodPostureCounter += 1
                    
                    if (alertFlag == true){
                        alertCounter = alertCounter * 0.5
                    }else{
                        alertCounter -= 1
                    }  
                }
                
                if (sensibilityTime == 0){
                    if (alertCounter > 30){
                        self.present(alert, animated: true, completion: nil)
                    }
                }else if (alertCounter > 120 * sensibilityTime){
                        self.present(alert, animated: true, completion: nil)
                    }
                
                let balance = roundDec(Float((goodPostureCounter*100)/postureCounter))
                if (balance > 50){
                    balanceLabel.textColor = UIColor.green
                }else{
                    balanceLabel.textColor = UIColor.red
                }
                balanceLabel.text = "Post. corr.: \(String(balance)) %"
                
                if( alertFlagBalance == false && balance < 50 && postureCounter > 120){
                    self.present(alertBalance, animated: true, completion: nil)
                }
                
                mean = roundDec((mean*meanCounter + absoluteHeadInclination)/(meanCounter + 1))
                meanCounter += 1
                meanInclinationLabel.text = "Media incl.: \(mean) °"
                
            }else{
                
                absoluteTiltLabel.text = "Tilt abs: 0.0°"
                
                relativeTiltLabel.text = "Tilt rel: 0.0°"
                
                inclinationLabel.text = "Incl. rel: 0.0° abs: 0.0°"
                
                cameraInclinationLabel.text = "Incl. cam.: 0.0°"
                
                postureStatusLabel.text = ""
                
                meanInclinationLabel.text = "Media incl.: "
                
                balanceLabel.text = "Post. corr.:"
                
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
            distanceLabel.text = "Troppo vicino alla cam"
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

