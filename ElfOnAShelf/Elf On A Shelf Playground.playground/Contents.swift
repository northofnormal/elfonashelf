import Foundation
import UIKit

// URL for weather API
https://api.wunderground.com/api/b193c8afeeecdbb2/conditions/q/AK/North_Pole.json

// request in viewDidLoad
guard let url = URL(string: "https://api.wunderground.com/api/b193c8afeeecdbb2/conditions/q/AK/North_Pole.json") else { return }

var request = URLRequest(url: url)
request.httpMethod = "GET"
let session = URLSession.shared

session.dataTask(with: request) { data, response, error in
    if error != nil {
        print("🚨🚨🚨🚨🚨 \(error.debugDescription)")
    } else {
        print("🎁🎁🎁🎁🎁 Made It!")
    }
    }.resume()

// After a succesful call, let's see what data we get:
guard let newData = data else { return }
let jsonString = String(data: newData, encoding: String.Encoding.utf8)
print(jsonString ?? "🚨🚨🚨🚨🚨 Unable to parse data into a string")

// IBoutlet for NPVC swipe gesture recognizer
@IBAction func swipeLeft() {
    performSegue(withIdentifier: "NorthPoleToSantaClaus", sender: self)
}

// IBOutlet for SCVC swipe gesture recognizer
@IBAction func swipeRight() {
    performSegue(withIdentifier: "SantaClausToNorthPole", sender: self)
}

// Structs for Codable
struct CurrentObservation: Codable {
    let current_observation: TemperatureInfo
}

struct TemperatureInfo: Codable {
    let weather: String
    let temp_f: Double
    let windchill_f: String
    
}

// Decoding for free:
guard let jsonData = jsonString?.data(using: .utf8) else { return }
let decoder = JSONDecoder()
let decodedData = try? decoder.decode(CurrentObservation.self, from: jsonData)

guard let weatherWeCareAbout = decodedData?.current_observation else { return }
print("weather: \(weatherWeCareAbout.weather), temp: \(weatherWeCareAbout.temp_f), windchill: \(weatherWeCareAbout.windchill_f)")

// custom coding keys
private enum CodingKeys: String, CodingKey {
    case weather, temp = "temp_f", windchill = "windchill_f"
}

// let's make this useful
// in the protocol
func fetchTemperature(closure: @escaping (TemperatureInfo) -> Void)

guard let weatherWeCareAbout = decodedData?.current_observation else { return }
closure(weatherWeCareAbout) // <- add this line

// in the view controllers, in vdl
fetchTemperature { info in
    DispatchQueue.main.async {
        self.temperatureLabel.text = "weather: \(info.weather), temp: \(info.temp), windchill: \(info.windchill)"
    }
}

// swipable
import UIKit

protocol Swipable { }

extension Swipable where Self: UIViewController {
    
    func swipe(direction: String) {
        performSegue(withIdentifier: direction, sender: self)
    }
    
}

// set up the configuration for sceneView in vdl
let configuration = ARWorldTrackingConfiguration()
sceneView.session.run(configuration)

// pause the session when the view disappears
override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    sceneView.session.pause()
}

// add horizontal plane detection in vdl
configuration.planeDetection = .horizontal

sceneView.delegate = self

// extract out a new method
func setupARScene() {
    sceneView.delegate = self
    let scene = SCNScene()
    sceneView.scene = scene
    
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
    sceneView.session.run(configuration)
}

// in VirtualPlane
var anchor: ARPlaneAnchor!
var planeGeometry: SCNPlane!

required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
}

// initializing the anchor pt 1
init(anchor: ARPlaneAnchor) {
    super.init()
    
    self.anchor = anchor
    planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
    
    let material = SCNMaterial()
    material.diffuse.contents = UIColor.white.withAlphaComponent(0.50)
    
    planeGeometry.materials = [material]
    
}

// pull out planeMaterial
func initializePlaneMaterial() -> SCNMaterial {
    let material = SCNMaterial()
    material.diffuse.contents = UIColor.white.withAlphaComponent(0.50)
    
    return material
}

//initializing the anchor pt 2
let planeNode = SCNNode(geometry: planeGeometry)
planeNode.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)

// update plane material dimensions
func updatePlaneMaterialDimensions() {
    let material = planeGeometry.materials.first
    let width = Float(planeGeometry.width)
    let height = Float(planeGeometry.height)
    
    material?.diffuse.contentsTransform = SCNMatrix4MakeScale(width, height, 1.0)
}

// initializing the anchor pt 3
updatePlaneMaterialDimensions()
addChildNode(planeNode)

// updating NPVC SCNDelegate methods pt 1
var planes = [UUID: VirtualPlane]() // add to the VC

func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    if let arPlaneAnchor = anchor as? ARPlaneAnchor {
        let plane = VirtualPlane(anchor: arPlaneAnchor)
        self.planes[arPlaneAnchor.identifier] = plane
        node.addChildNode(plane)
    }
}

// update with new anchor in virtualplane.swift
func updateWithNewAnchor(anchor: ARPlaneAnchor) {
    planeGeometry.width = CGFloat(anchor.extent.x)
    planeGeometry.height = CGFloat(anchor.extent.z)
    
    position = SCNVector3(anchor.center.x, 0, anchor.center.z)
    
    updatePlaneMaterialDimensions()
}

// updte NPVC SCNDelegateMethods pt 2
func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    if let arPlaneAnchor = anchor as? ARPlaneAnchor, let plane = planes[arPlaneAnchor.identifier] {
        plane.updateWithNewAnchor(anchor: arPlaneAnchor)
    }
}

// update NPVC SCNDElegateMethods pt 3
func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
    if let arPlaneAnchor = anchor as? ARPlaneAnchor, let index = planes.index(forKey: arPlaneAnchor.identifier) {
        planes.remove(at: index)
    }
}

// sceneview debug options
sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]

// ARElfSessionStatus
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

// currentElfStat var
var currentElfState = ARElfSessionState.initialized {
    didSet {
        DispatchQueue.main.async {
            self.statusLabel.text = self.currentElfState.description
        }
        if self.currentElfState == .failed {
            self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
                node.removeFromParentNode()
                
            }
        }
    }
}

// extract out to cleanUpNodes()
func cleanUpNodes() {
    self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
        node.removeFromParentNode()
    }
}

// update planes to update ARElfState
didSet {
    if planes.count > 0 {
        currentElfState = .ready
    } else {
        if currentElfState == .ready {
            currentElfState = .initialized
        }
    }
}

// cleanup methods
func session(_ session: ARSession, didFailWithError error: Error) {
    currentElfState = .failed
}

func sessionWasInterrupted(_ session: ARSession) {
    currentElfState = .temporarilyUnavailable
}

func sessionInterruptionEnded(_ session: ARSession) {
    currentElfState = .ready
}

// adding an elf node
var elfNode: SCNNode?

func initializeElfNode() {
    let elfScene = SCNScene(named: "santa_hat.dae")
    elfNode = elfScene?.rootNode.childNode(withName: "santa_hat", recursively: false)
}

// call in vdl
initializeElfNode()

// override touches began
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
    // we need to make sure we are actually on a plane
}

// virtual plane property
var selectedPlane: VirtualPlane?

func virtualPlaneProperlySet(touchPoint: CGPoint) -> VirtualPlane? {
    let hits = sceneView.hitTest(touchPoint, types: .existingPlaneUsingExtent)
    guard hits.count > 0 else { return nil  }
    guard let firstHit = hits.first, let identifier = firstHit.anchor?.identifier, let plane = planes[identifier] else {
        return nil
    }
    
    selectedPlane = plane
    return plane
}

// call the above method in touchesBegan:
guard let plane = virtualPlaneProperlySet(touchPoint: touchPoint) else { return }

//add elf to plane
func addElfToPlane(plane: VirtualPlane, at point: CGPoint) {
    let hits = sceneView.hitTest(point, types: .existingPlaneUsingExtent)
    guard hits.count > 0 else { return }
    guard let firstHit = hits.first else { return }
    
    guard let anElf = elfNode?.clone() else { return }
    anElf.position = SCNVector3Make(firstHit.worldTransform.columns.3.x, firstHit.worldTransform.columns.3.y, firstHit.worldTransform.columns.3.z)
    sceneView.scene.rootNode.addChildNode(anElf)
}

// add call to add elf to touches began
addElfToPlane(plane: plane, at: touchPoint)


