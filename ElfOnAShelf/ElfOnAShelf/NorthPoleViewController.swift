//
//  NorthPoleViewController.swift
//  ElfOnAShelf
//
//  Created by Anne Cahalan on 12/29/17.
//  Copyright © 2017 Anne Cahalan. All rights reserved.
//

import ARKit
import Foundation
import UIKit

class NorthPoleViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBAction func swipeLeft() {
        swipe(direction: "NorthPoleToSantaClaus")
    }
    
    var state = "AK"
    var city = "North_Pole"
    var selectedPlane: VirtualPlane?
    
    var planes = [UUID: VirtualPlane]() {
        didSet {
            if planes.count > 0 {
                currentElfState = .ready
            } else {
                if currentElfState == .ready {
                    currentElfState = .initialized
                }
            }
        }
    }
    
    var currentElfState = ARElfSessionState.initialized {
        didSet {
            DispatchQueue.main.async {
                self.statusLabel.text = self.currentElfState.description
            }
            if self.currentElfState == .failed {
                cleanUpNodes()
            }
        }
    }
    
    var elfNode: SCNNode?
    
    func initializeElfNode() {
        let elfScene = SCNScene(named: "santa_hat.dae")
        elfNode = elfScene?.rootNode.childNode(withName: "santa_hat", recursively: false)
    }
    
    func cleanUpNodes() {
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
            node.removeFromParentNode()
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchTemperature { info in
            DispatchQueue.main.async {
                self.temperatureLabel.text = "weather: \(info.weather), temp: \(info.temp), windchill: \(info.windchill)"
            }
        }
        
        setupARScene()
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        if planes.count > 0 {
            currentElfState = .ready
        }
        
        initializeElfNode()
    }
    
    func setupARScene() {
        sceneView.delegate = self
        let scene = SCNScene()
        sceneView.scene = scene
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            print("👆🏻🚫👆🏻🚫👆🏻🚫 Unable to identify touches on any plane, ignoring everything.")
            return
        }
        
        guard currentElfState == .ready else {
            print("🧘🏼‍♀️🧘🏼‍♀️🧘🏼‍♀️🧘🏼‍♀️🧘🏼‍♀️🧘🏼‍♀️ Planes aren't ready yet. Be patient.")
            return
        }
        
        let touchPoint = touch.location(in: sceneView)
        guard let plane = virtualPlaneProperlySet(touchPoint: touchPoint) else { return }
        addElfToPlane(plane: plane, at: touchPoint)
    }
    
    func virtualPlaneProperlySet(touchPoint: CGPoint) -> VirtualPlane? {
        let hits = sceneView.hitTest(touchPoint, types: .existingPlaneUsingExtent)
        guard hits.count > 0 else { return nil  }
        guard let firstHit = hits.first, let identifier = firstHit.anchor?.identifier, let plane = planes[identifier] else {
            return nil
        }
        
        selectedPlane = plane
        return plane
    }
    
    func addElfToPlane(plane: VirtualPlane, at point: CGPoint) {
        let hits = sceneView.hitTest(point, types: .existingPlaneUsingExtent)
        guard hits.count > 0 else { return }
        guard let firstHit = hits.first else { return }
        
        guard let anElf = elfNode?.clone() else { return }
        anElf.position = SCNVector3Make(firstHit.worldTransform.columns.3.x, firstHit.worldTransform.columns.3.y, firstHit.worldTransform.columns.3.z)
        sceneView.scene.rootNode.addChildNode(anElf)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
        currentElfState = .temporarilyUnavailable
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        currentElfState = .failed
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        currentElfState = .temporarilyUnavailable
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        currentElfState = .ready
    }
    
}

extension NorthPoleViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor {
            let plane = VirtualPlane(anchor: arPlaneAnchor)
            self.planes[arPlaneAnchor.identifier] = plane
            node.addChildNode(plane)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor, let plane = planes[arPlaneAnchor.identifier] {
            plane.updateWithNewAnchor(anchor: arPlaneAnchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor, let index = planes.index(forKey: arPlaneAnchor.identifier) {
            planes.remove(at: index)
        }
    }
    
}

extension NorthPoleViewController: TemperatureFetching { }

extension NorthPoleViewController: Swipable { }

enum ARElfSessionState: String, CustomStringConvertible {
    case initialized = "initialized", ready = "ready", temporarilyUnavailable = "temporarily unavailable", failed = "failed"
    
    var description: String {
        switch self {
        case .initialized:
            return "🕵🏻‍♀️ Look for a plane to place an elf"
        case .ready:
            return "🧚🏻‍♂️ Place your elf"
        case .temporarilyUnavailable:
            return "🎅🏻 Checking my list, please wait"
        case .failed:
            return "😡 Someone's been naughty"
        }
    }
}


