//
//  Sea.swift
//  SpriteKit course
//
//  Created by Karol Pilch on 21/03/2016.
//  Copyright © 2016 Karol Pilch. All rights reserved.
//

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

protocol Arithmetic {
	func -(l: Self, r: Self) -> Self
	func +(l: Self, r: Self) -> Self
	func *(l: Self, r: Self) -> Self
}
extension Float: Arithmetic {}
extension Double: Arithmetic {}
extension CGFloat: Arithmetic {}

private class Randomizer {
	static private let randomizer = GKARC4RandomSource()
	
	// Returns a number that's randomly different from the number parameter. Spread is controlled by factor.
	static private func randomize(number: CGFloat, factor: Double = 1) -> CGFloat {
		let randomization = CGFloat(randomizer.nextUniform() * 2 - 1)   // A number between -1 and 1
		let difference = randomization * number * CGFloat(factor)
		return number + difference
	}
	
	static func between<N where N: Arithmetic, N: FloatLiteralConvertible>(start: N, _ end: N) -> N {
		let difference = end - start
		let random = Double(randomizer.nextUniform())
		return start + difference  * N(floatLiteral: random as! N.FloatLiteralType)
	}
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
	var colorRange: CGFloat = 0
	
	
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
	
	var wavePositionRange: Double = 0
	
	
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
		newWave.blendMode = SKBlendMode.Add
		newWave.colorBlendFactor = 0.8
        
        // TODO: Change how this works to get right colours. Maybe colour the sprite?
		
		// TODO: Change how this works to get right colours. Maybe colour the sprite?
		
		// Add physics body if needed
		addPhysicsBodyToWave(newWave)
		
		return newWave
	}
	
	
	
	// Adds waves to this node
	func addWaves() {
		
		let standardSpacing = waveSize * 0.7
		
		var positionX = CGFloat(0.0 - (width / 2))
		repeat {
			positionX += Randomizer.randomize(standardSpacing, factor: wavePositionRange)
			let positionY = standardSpacing - Randomizer.randomize(standardSpacing, factor: wavePositionRange)
			let wave = newWave(CGPoint(x: positionX, y: positionY))
			
			// Add motion
			let radius = Randomizer.randomize(standardSpacing, factor: wavePositionRange) / 2
			wave.position = CGPoint(x: wave.position.x - radius, y: wave.position.y - radius)
			let period = Double(Randomizer.randomize(2, factor: 0.5))
			
			// Make a circle and move the wave around it
			// xcdoc://?url=developer.apple.com/library/ios/documentation/SpriteKit/Reference/SKAction_Ref/index.html#//apple_ref/occ/clm/SKAction/followPath:asOffset:orientToPath:duration:
			
			
			self.addChild(wave)
		} while (positionX < (width / 2))
	}
	
	init(width: CGFloat, size: CGFloat) {
		self.width = width
		self.waveSize = size
		super.init()
	}
	
	// ***** NSCoding conformance
	
	override func encodeWithCoder(aCoder: NSCoder) {
		baseColor.encodeWithCoder(aCoder)
		aCoder.encodeFloat(Float(waveSize), forKey: "waveSize")
		aCoder.encodeFloat(Float(width), forKey: "width")
	}

	required init?(coder aDecoder: NSCoder) {
		// This probably happens only when we push it out of memory.
		width = CGFloat(aDecoder.decodeFloatForKey("width"))
		waveSize = CGFloat(aDecoder.decodeFloatForKey("waveSize"))
		
		if let decodedColor = UIColor.init(coder: aDecoder) {
			baseColor = decodedColor
		}
		else {
			fatalError("init(coder) failed to decode sea color.")
		}
		
		super.init(coder: aDecoder)
	}
}