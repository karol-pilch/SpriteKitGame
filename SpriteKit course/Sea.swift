//
//  Sea.swift
//  SpriteKit course
//
//  Created by Karol Pilch on 21/03/2016.
//  Copyright © 2016 Karol Pilch. All rights reserved.
//
/*
import SpriteKit
import GameplayKit

private class SeaPhysicsBody {
	var categoryBitMask: UInt32 = 0
	var collisionBitMask: UInt32 = UINT32_MAX
	var contactTestBitMask: UInt32 = UINT32_MAX
	
	let affectedByGravity: Bool = false
	let allowsRotation: Bool = false
	let dynamic: Bool = false
}

internal class Sea: SKNode {
	
	
	// ***** Dimensions
	
	let width: CGFloat
	let waveSize: CGFloat
	
	
	//***** Color
	
	// Base color for waves
	var baseColor: UIColor = UIColor.init(red: 0, green: 0.5, blue: 1, alpha: 1) {
		didSet {
			// Set new color for waves...

		}
	}
	// How much the wave colors should vary
	let colorRange: CGFloat = 0
	
	
	// ***** Node behavour
	
	// Keeps track of important physics properties
	private var physicsConfiguration: SeaPhysicsBody? = nil
	
	// Applies physics properties to bodies of children
	override var physicsBody: SKPhysicsBody? {
		get {
			var waveBodies: [SKPhysicsBody] = []
			self.enumerateChildNodesWithName("wave") { (node: SKNode, ptr: UnsafeMutablePointer<ObjCBool>) -> Void in
				if let wave = node as? SKSpriteNode {
					if wave.physicsBody != nil { waveBodies.append(wave.physicsBody!) }
				}
			}
			
			return SKPhysicsBody(bodies: waveBodies)
		}
		set {
			if let newBody = newValue {
				if physicsConfiguration == nil {
					physicsConfiguration = SeaPhysicsBody()
				}
				
				physicsConfiguration!.categoryBitMask = newBody.categoryBitMask
				physicsConfiguration!.collisionBitMask = newBody.collisionBitMask
				physicsConfiguration!.contactTestBitMask = newBody.contactTestBitMask
				
				// Set new physics properties to all waves
				self.enumerateChildNodesWithName("wave") { (node: SKNode, ptr: UnsafeMutablePointer<ObjCBool>) -> Void in
					if let wave = node as? SKSpriteNode {
						// Add a body if the wave doesn't have one
						if wave.physicsBody == nil {

						}
						
						wave.physicsBody?.categoryBitMask = self.physicsConfiguration!.categoryBitMask
						wave.physicsBody?.collisionBitMask = self.physicsConfiguration!.categoryBitMask
						wave.physicsBody?.contactTestBitMask = self.physicsConfiguration!.contactTestBitMask
					}
				}
			}
		}
	}
	
	
	// ***** Internal seaworks
	
	// Returns a color that's a bit (or a lot, depending on range) different from baseColor
	private func randomizeColor() -> UIColor {
		// Get base values
		var red: CGFloat = 0
		var green: CGFloat = 0
		var blue: CGFloat = 0
		var alpha: CGFloat = 0
		baseColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
		
		// Multiply them by a random number
		let randomizer = GKARC4RandomSource()
		red *= 1 - (colorRange * CGFloat(randomizer.nextUniform()))
		green *= 1 - (colorRange * CGFloat(randomizer.nextUniform()))
		blue *= 1 - (colorRange * CGFloat(randomizer.nextUniform()))
		
		// Return a new random color
		return UIColor(red: red, green: green, blue: blue, alpha: alpha)
	}
	
	// Adds physics body to a wave if one has been configured for the Sea
	private func addPhysicsBodyToWave(wave: SKSpriteNode) {
		if let config = physicsConfiguration {
			let texture = SKTexture(imageNamed: "wave")
			let newBody = SKPhysicsBody(texture: texture, size: CGSize(width: texture.size().width / texture.size().height * waveSize, height: waveSize))
			newBody.categoryBitMask = config.categoryBitMask
			newBody.collisionBitMask = config.collisionBitMask
			newBody.contactTestBitMask = config.contactTestBitMask
			newBody.affectedByGravity = config.affectedByGravity
			newBody.allowsRotation = config.allowsRotation
			newBody.dynamic = config.dynamic
			
			wave.physicsBody = newBody
		}
	}
	
	// Adds a new wave to the sea
	private func newWave(position: CGPoint) -> SKSpriteNode {
		let texture = SKTexture(imageNamed: "wave")
		let waveColor = randomizeColor()
		
		// Configure the node
		let newWave = SKSpriteNode(texture: texture, color: waveColor, size: CGSize(width: texture.size().width / texture.size().height * waveSize, height: waveSize))
		newWave.position = position
		newWave.blendMode = SKBlendMode.Alpha
		newWave.colorBlendFactor = 1
		
		// Add physics body if needed
		addPhysicsBodyToWave(newWave)

		return newWave
	}
	
	// Adds waves to this node
	private func addWaves() {
		// Go along the width and randomize positions of waves
	}
	
	init(width: CGFloat, size: CGFloat) {
		self.width = width
		self.waveSize = size
		super.init()
		
	}
	
	// ***** NSCoding conformance
	
	override func encodeWithCoder(aCoder: NSCoder) {
		baseColor.encodeWithCoder(aCoder)
		aCoder.encodeFloat(Float(width), forKey: "width")
	}

	required init?(coder aDecoder: NSCoder) {
		// This probably happens only when we push it out of memory.
		width = CGFloat(aDecoder.decodeFloatForKey("width"))
		if let decodedColor = UIColor.init(coder: aDecoder) {
			baseColor = decodedColor
		}
		else {
			fatalError("init(coder) failed to decode sea color.")
		}
		
		super.init(coder: aDecoder)
	}
}

*/*/