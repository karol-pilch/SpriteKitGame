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
			addWaves()
		}
	}
	// How much the wave colors should vary
	var colorRange: Double = 0 {
		didSet {
			addWaves()
		}
	}
	
	
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
							self.addPhysicsBodyToWave(wave)
						}
						else {
							wave.physicsBody?.categoryBitMask = self.physicsConfiguration!.categoryBitMask
							wave.physicsBody?.collisionBitMask = self.physicsConfiguration!.categoryBitMask
							wave.physicsBody?.contactTestBitMask = self.physicsConfiguration!.contactTestBitMask
						}
					}
				}
			}
		}
	}
	
	// Must be set to true before showing.
	var ready: Bool = false {
		didSet {
			if (ready == true) {
				addWaves()
			}
		}
	}
	
	// ***** Internal seaworks
	
	var wavePositionRange: Double = 0 {
		didSet {
			addWaves()
		}
	}
	
	var waveDensity: Double = 2.5 {
		didSet {
			addWaves()
		}
	}
	
	
	// Returns a color that's a bit (or a lot, depending on range) different from baseColor
	private func randomizeColor() -> UIColor {
		// Get base values
		var red: CGFloat = 0
		var green: CGFloat = 0
		var blue: CGFloat = 0
		var alpha: CGFloat = 0
		baseColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
		
		
		// Multiply them by a random number
		red = Randomizer.randomize(red, factor: colorRange)
		green = Randomizer.randomize(green, factor: colorRange)
		blue = Randomizer.randomize(blue, factor: colorRange)
		
		// Return a new random color
		return UIColor(red: red, green: green, blue: blue, alpha: alpha)
	}
	
	// Adds physics body to a wave if one has been configured for the Sea
	private func addPhysicsBodyToWave(wave: SKSpriteNode) {
		if let config = physicsConfiguration {
			let texture = SKTexture(imageNamed: "wave-white")
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
		newWave.name = "wave"
		
		// Add physics body if needed
		addPhysicsBodyToWave(newWave)
		
		return newWave
	}
	
	
	
	// Adds waves to this node
	func addWaves() {
		
		if !ready { return }
		
		print("adding waves")
		
		// Remove all old waves
		enumerateChildNodesWithName("wave") { (wave: SKNode, ptr: UnsafeMutablePointer<ObjCBool>) in
			wave.removeFromParent()
		}
		
		let distance = waveSize / CGFloat(waveDensity)
		
		var x = -width / 2 - distance
		repeat {
			x += Randomizer.randomize(distance, factor: wavePositionRange)
			let y = -waveSize / 2 + Randomizer.randomize(distance, factor: wavePositionRange)
			let wave = newWave(CGPoint(x: x, y: y))
			
			wave.zPosition = Randomizer.between(0.0, 10.0)
			
			// Add motion
			let radius = Randomizer.randomize(distance, factor: wavePositionRange) / 2
			wave.position = CGPoint(x: wave.position.x - radius, y: wave.position.y - radius)
			let period = NSTimeInterval(Randomizer.randomize(2, factor: 0.5))
			
			// Circular motion
			let circle: CGMutablePathRef = CGPathCreateMutable()
			CGPathAddArc(circle, nil, x, y, radius, 0, CGFloat(2 * M_PI), true)
			let circleAction = SKAction.followPath(circle, asOffset: false, orientToPath: false, duration: period)
			wave.runAction(SKAction.repeatActionForever(circleAction))
			
			// Slight rotation
			let maxRotationAngle = Randomizer.randomize(CGFloat(M_PI / 2 * wavePositionRange), factor: wavePositionRange)
			let rotateRight = SKAction.rotateByAngle(2 * maxRotationAngle, duration: period / 2)
			rotateRight.timingMode = SKActionTimingMode.EaseInEaseOut
			let rotateLeft = SKAction.rotateByAngle(-2 * maxRotationAngle, duration: period / 2)
			rotateLeft.timingMode = SKActionTimingMode.EaseInEaseOut
			let rotateAction = SKAction.sequence([rotateRight, rotateLeft])
			wave.zRotation = -maxRotationAngle
			wave.runAction(SKAction.repeatActionForever(rotateAction))
			
			self.addChild(wave)
			
		} while (x < (width / 2))
	}
	
	init(width: CGFloat, size: CGFloat) {
		self.width = width
		self.waveSize = size
		super.init()
	}
	
	// ***** NSCoding conformance
	
	override func encodeWithCoder(aCoder: NSCoder) {
		// TODO: Actually encode all variables.
		baseColor.encodeWithCoder(aCoder)
		aCoder.encodeFloat(Float(waveSize), forKey: "waveSize")
		aCoder.encodeFloat(Float(width), forKey: "width")
		aCoder.encodeDouble(colorRange, forKey: "colorRange")
		aCoder.encodeDouble(wavePositionRange, forKey: "wavePositionRange")
		aCoder.encodeDouble(waveDensity, forKey: "waveDensity")
		aCoder.encodeBool(ready, forKey: "ready")
	}
	
	required init?(coder aDecoder: NSCoder) {
		// This probably happens only when we push it out of memory.
		
		width = CGFloat(aDecoder.decodeFloatForKey("width"))
		waveSize = CGFloat(aDecoder.decodeFloatForKey("waveSize"))
		colorRange = aDecoder.decodeDoubleForKey("colorRange")
		wavePositionRange = aDecoder.decodeDoubleForKey("wavePositionRange")
		waveDensity = aDecoder.decodeDoubleForKey("waveDensity")
		ready = aDecoder.decodeBoolForKey("ready")
		
		if let decodedColor = UIColor.init(coder: aDecoder) {
			baseColor = decodedColor
		}
		else {
			fatalError("init(coder) failed to decode sea color.")
		}
		
		super.init(coder: aDecoder)
	}
}