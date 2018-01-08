//
//  VirtualPlane.swift
//  ElfOnAShelf
//
//  Created by Anne Cahalan on 1/7/18.
//  Copyright © 2018 Anne Cahalan. All rights reserved.
//

import ARKit
import UIKit

class VirtualPlane: SCNNode {

    var anchor: ARPlaneAnchor!
    var planeGeometry: SCNPlane!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(anchor: ARPlaneAnchor) {
        super.init()
        
        self.anchor = anchor
        planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        let material = initializePlaneMaterial()
        planeGeometry.materials = [material]
        
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
        
        updatePlaneMaterialDimensions()
        addChildNode(planeNode)
    }
    
    func initializePlaneMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white.withAlphaComponent(0.50)
        
        return material
    }
    
    func updatePlaneMaterialDimensions() {
        let material = planeGeometry.materials.first
        let width = Float(planeGeometry.width)
        let height = Float(planeGeometry.height)
        
        material?.diffuse.contentsTransform = SCNMatrix4MakeScale(width, height, 1.0)
    }
    
    func updateWithNewAnchor(anchor: ARPlaneAnchor) {
        planeGeometry.width = CGFloat(anchor.extent.x)
        planeGeometry.height = CGFloat(anchor.extent.z)
        
        position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        
        updatePlaneMaterialDimensions()
    }
    
}
