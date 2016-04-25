//
//  GameScene.swift
//  SpriteKit course
//
//  Created by Karol Pilch on 01/02/2016.
//  Copyright (c) 2016 Karol Pilch. All rights reserved.
//

import SpriteKit
import AVFoundation

extension CGPoint {
	func distanceFrom (other: CGPoint) -> CGFloat {
		let dx = x - other.x
		let dy = y - other.y
		return sqrt((dx * dx) + (dy * dy))
	}
}

extension CGVector {
	var length: CGFloat {
		get {
			return sqrt(pow(dx, 2) + pow(dy, 2))
		}
	}
}

extension SKScene {
	func absolutePosition(node: SKNode?) -> CGPoint? {
		if node == nil { return nil }
		
		var result = node!.position
		
		var parent = node!.parent
		while (parent != nil) {
			if let node = parent {
				if node.isEqualToNode(self) { return result }	// Returning result only for own children
				
				result.x += node.position.x
				result.y += node.position.y
				
				parent = node.parent
			}
			else { break }
		}
		
		return nil
	}
}

// SKPhysicsContactDelegate lets us respond to contact events
class GameScene: SKScene, SKPhysicsContactDelegate {
	
	// We set those here to be able to easily use the categories with bitwise operators.
	// We have to manually put the numbers in the scene file to assign objects to categories.
	struct NodeCategory {
		static let Obstacle: UInt32				= 0b1 << 0	// 1
		static let Destructible: UInt32		= 0b1 << 1	// 2
		static let Sparks: UInt32					= 0b1 << 2	// 4
		static let Orange: UInt32					= 0b1 << 3	// 8
		static let Blue: UInt32						= 0b1 << 4	// 16
		static let Ball: UInt32						= 0b1 << 5	// 32
		static let FlyThrough: UInt32			= 0b1 << 6	// 64
		static let Bucket: UInt32					= 0b1 << 7	// 128
		static let Sea: UInt32						= 0b1 << 8	// 256
		static let Boundary : UInt32			= 0b1 << 9
		
		static let None: UInt32						= 0
		static let All: UInt32						= UINT32_MAX
	}
	
	let orangeColor = UIColor(red: 1, green: 164.0/256.0, blue: 0, alpha: 1)
	let blueColor = UIColor(red: 37/256.0, green: 174/256.0, blue: 188/256.0, alpha: 1)
	
/*
	A bit more about masks
	======================
	
	There are four masks: Category, Collision, Field, and Contact.
	
	*Category* mask helps other objects decide whether to collide with this object.
	*Collision* mask is compared against other object's Category mask and if the result
	   is not 0, the collision occurs.
	*Field* mask I haven't learned about yet
	*Contact* mask is compared against the Category mask of another object (just like
	   the Collision mask) and if the result is non-zero, the delegate will be noti-
	   fied that the contact occurred.
*/
	
/*
	And a little bit about gravity fields
	=====================================
	
	Gravity fields can be added to the scene in the scene editor. Probably in code as well,
	but that wasn't explained in the course. They define different kinds of gravity.
	What's really cool is that you can define category masks on the fields, and then field 
	masks on nodes, and this way control which nodes are affected by which field.
*/
	
/*
	Homework
	========
	
	1. Animate the ball as it travels - DONE
	2. Add smoke to the ball - DONE
	3. Finish the camera video.

*/
	
	var cannon: SKSpriteNode!
	var cannonPosition = CGPointZero
	var score: Int = 0
	var followCam: SKCameraNode!
	
	var ball: SKSpriteNode? = nil
	var isReadyToShoot: Bool = true
	
	var touchLocation: CGPoint = CGPointZero
	var backgroundMusic: SKAudioNode!
	
	override func didMoveToView(view: SKView) {
		// Need to set up self as the contact delegate
		self.physicsWorld.contactDelegate = self;
		
		// Connect nodes to our variables
		cannon = self.childNodeWithName("//cannon") as! SKSpriteNode
		if let pos = absolutePosition(cannon) { cannonPosition = pos }
		
		// Find the follow cam
		self.followCam = self.childNodeWithName("camera") as! SKCameraNode
		
		// Process nodes in the scene
		for nodeName in ["rotatingSquare", "orangePeg", "bluePeg", "leftWall", "rightWall", "ceiling", "ground", "bucket"] {
			enumerateChildNodesWithName(nodeName, usingBlock: { (node: SKNode, ptr: UnsafeMutablePointer<ObjCBool>) -> Void in
				if node.physicsBody != nil {
					switch nodeName {
						case "rotatingSquare":
							node.physicsBody!.categoryBitMask = NodeCategory.Obstacle
						case "orangePeg":
							node.physicsBody!.categoryBitMask = NodeCategory.Destructible | NodeCategory.Sparks | NodeCategory.Orange
						case "bluePeg":
							node.physicsBody!.categoryBitMask = NodeCategory.Destructible | NodeCategory.Sparks | NodeCategory.Blue
						case "leftWall", "rightWall", "ceiling", "ground":
							node.physicsBody!.categoryBitMask = NodeCategory.Boundary
						case "bucket":
							node.physicsBody!.categoryBitMask = NodeCategory.Bucket
							self.wobbleBucket(node, delta: 15)
						default: break
					}
				}
			})
		}
		
		// Add the sea on the bottom, in three 'layers'
		var y = -880.0
		var size = 170.0
		for i in 1...2 { // DEBUG FIXME
			let factor = Double(i)
			if i > 1 {
				y += size / 2.5
			}
			size = size * factor / pow(factor, 2)
			
			let sea = Sea(width: 1080, size: CGFloat(size))
			sea.baseColor = UIColor(red: 145 / 256, green: 178 / 256, blue: 211 / 256, alpha: 1)
			sea.colorRange = 0.2
			sea.wavePositionRange = 0.3
			sea.waveDensity = 2.6
			sea.position = CGPoint(x: 1425.0, y: CGFloat(y))
			sea.zPosition = CGFloat(-i)
			
			let seaBody = SKPhysicsBody(circleOfRadius: 1)
			seaBody.affectedByGravity = false
			seaBody.allowsRotation = false
			seaBody.dynamic = false
			
			seaBody.categoryBitMask = NodeCategory.Sea
			seaBody.contactTestBitMask = NodeCategory.None
			seaBody.collisionBitMask = NodeCategory.None
			sea.physicsBody = seaBody
			sea.ready = true
			self.addChild(sea)
		}
		
		// Start playing the background music
		runAction(SKAction.waitForDuration(0.1), completion: {
			let music = SKAudioNode(fileNamed: "background.mp3")
			self.addChild(music)
			self.backgroundMusic = music
		})
		
		// Preload sounds used in the scene
		let sounds = ["splash.mp3", "peg", "plum", "shot", "explosion"]
		for sound in sounds {
			let fileName: String
			let fileExtension: String
			if let dotRange = sound.rangeOfString(".") {
				fileName = sound.substringToIndex(dotRange.startIndex)
				fileExtension = sound.substringFromIndex(dotRange.startIndex)
			}
			else {
				fileName = sound
				fileExtension = "wav"
			}
			if let path = NSBundle.mainBundle().pathForResource(fileName, ofType: fileExtension) {
				do {
					let player = try AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: path))
					player.prepareToPlay()
				} catch {
					print("Could not preload the sound \"\(sound)\".")
				}
			}
		}
	}
	
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if let firstTouch = touches.first {
			touchLocation = firstTouch.locationInNode(self)
		}
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if let touch = touches.first {
			shootBall(fromPosition: absolutePosition(cannon)!, targetPosition: touch.locationInNode(self))
		}
	}
	
	override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if let firstTouch = touches.first {
			touchLocation = firstTouch.locationInNode(self)
		}
	}
	
	override func update(currentTime: CFTimeInterval) {
		// Calculate the cannon angle and update it
		let newAngle = atan2((touchLocation.x - cannonPosition.x), (touchLocation.y - cannonPosition.y))
		cannon.zRotation = -newAngle + CGFloat(M_PI/2)
		
		// Unset ball if it's been removed from the scene
		if self.ball != nil && !self.ball!.inParentHierarchy(self) {
			ballWillBeRemoved()
			self.ball = nil
		}
		
		// See if the ball is moving and destroy it if not
		if let ball = self.ball {
			ballUpdate(ball)
		}
	}
	
	var backgroundNodeColor: UIColor? = nil
	
	func didBeginContact(contact: SKPhysicsContact) {
		// Since all of our objects except for walls have their contact category as 0, they won't notify us about a collision.
		// Only the ball will, so we're sure that one of the bodies is the ball.
		
		let ball: SKPhysicsBody	// We don't need it for now
		let other: SKPhysicsBody
		if (contact.bodyA.categoryBitMask == NodeCategory.Ball) {
			ball = contact.bodyA
			other = contact.bodyB
		}
		else {
			ball = contact.bodyB
			other = contact.bodyA
		}
		
		// print("Contact of \(ball.node?.name) with \(other.node?.name)")
		
		let otherMask = other.categoryBitMask
		
		if otherMask & NodeCategory.Boundary != 0 {
			
		}
		
		if otherMask & NodeCategory.Destructible != 0 {
			other.node?.removeFromParent()
			self.runAction(SKAction.playSoundFileNamed("peg.wav", waitForCompletion: false))
		}
		
		if otherMask & NodeCategory.Sea != 0 {
			ballDisappearanceInfo = BallDestructionInfo(position: contact.contactPoint, destiny: .Drowning)
			ball.node?.removeFromParent()
		}
		
	
		if otherMask & NodeCategory.Bucket != 0 {
			bucketHit(ball.node)
		}
		
		if otherMask & NodeCategory.Sparks != 0 {
			
			// See if the node has a colour category
			let color: UIColor?
			if otherMask & NodeCategory.Orange != 0 { color = orangeColor }
			else if otherMask & NodeCategory.Blue != 0 { color = blueColor }
			else { color = nil }
			
			emitSparks(contact.contactPoint, color: color)
		}
	}
	
	var recentBallVelocities: [CGFloat] = []
	
	func ballUpdate(ball: SKSpriteNode) {
		let minSpeed: CGFloat = 300.0				// In pixels / second
		let measureInterval: Float = 1.5		// Seconds (approximate at 60 fps)
		let significantVelocities = Int(floor(measureInterval * 60))
		
		if let ballBody = ball.physicsBody {
			// Add the ball position to the list
			recentBallVelocities.append(ballBody.velocity.length)
			
			// Calculate average speed over the last measureInterval
			var sum: CGFloat = 0
			let start = max(0, recentBallVelocities.count -  significantVelocities)
			let end = recentBallVelocities.count
			let total = end - start
			for i in start ..< end {
				sum += recentBallVelocities[i]
			}
			
			let averageSpeed = sum / CGFloat(total)
			// print ("count: \(recentBallVelocities.count), start: \(start), end: \(end) avg: \(averageSpeed)")
			
			if (!followCam.hasActions()) {
				// Zoom in / out only when not currently zooming
				let zoom = (min: Float(0.5), max: Float(2.0))
				let speed = (min: Float(400), max: Float(3000))
				let velocity = min(speed.max, max(speed.min, Float(averageSpeed)))
				
				// Calculate the zoom value
				let factor = (zoom.min - zoom.max) / (speed.min - speed.max)
				let scale = CGFloat(factor * (velocity - speed.min) + zoom.min)
				
				followCam.setScale(scale)
			}
			
			if ballBody.resting || (recentBallVelocities.count >= significantVelocities && averageSpeed < minSpeed) {
				ballDisappearanceInfo = BallDestructionInfo(position: ball.position, destiny: .Explosion)
				ball.removeFromParent()
			}
		}
	}
	
	
	// The following two have information about what happened to the ball.
	enum BallFinalDestiny {
		case Drowning
		case Explosion
		case BucketLanding
	}
	
	struct BallDestructionInfo {
		var position: CGPoint = CGPointZero
		var destiny: BallFinalDestiny
	}
	
	var ballDisappearanceInfo: BallDestructionInfo? = nil
	
	// Executed before the ball is removed from the scene.
	func ballWillBeRemoved() {
		// Reset camera back to cannon
		followNode(self)
		recentBallVelocities.removeAll()
		
		if ballDisappearanceInfo == nil { return }
		
		let position = ballDisappearanceInfo!.position
		let destiny = ballDisappearanceInfo!.destiny
		
		// Emit sparks and / or sounds depending on destiny
		switch destiny {
		case .Drowning:
			emitSplash(position)
		case .Explosion:
			self.runAction(SKAction.playSoundFileNamed("explosion", waitForCompletion: false))
			emitSparks(position)
		default: break
		}
		
		// Remove disappearance info since it's been dealt with
		ballDisappearanceInfo = nil
	}
	
	func moveCamera(to: CGPoint, zoom: CGFloat = 1, duration: NSTimeInterval = 0.5) {
		followCam.runAction(cameraMoveAction(destination: to, zoom: zoom, duration: duration))
	}
	
	func cameraMoveAction(destination to: CGPoint, zoom: CGFloat = 1, duration: NSTimeInterval = 0.5) -> SKAction {
		let move = SKAction.moveTo(to, duration: duration)
		move.timingMode = SKActionTimingMode.EaseInEaseOut
		
		let zoom = SKAction.scaleTo(zoom, duration: duration)
		zoom.timingMode = SKActionTimingMode.EaseInEaseOut
		
		return SKAction.group([move, zoom])
	}
	
	func followNode(node: SKNode, zoom: CGFloat = 1) {
		if node.isEqualToNode(self) {
			// Reset the camera position
			let relativePosition: CGPoint?
			if let deathInfo = ballDisappearanceInfo {
				relativePosition = deathInfo.position
			}
			else {
				relativePosition = absolutePosition(followCam)
			}
			followCam.removeFromParent()
			
			if relativePosition != nil {
				followCam.position = relativePosition!
			}
			
			self.addChild(followCam)
			
			let cameraSequence = SKAction.sequence([
				cameraMoveAction(destination: CGPoint(x: 0, y: 2000), zoom: 4, duration: 1),
				SKAction.waitForDuration(1.2),
				cameraMoveAction(destination: CGPoint(x: -1555, y: 540))
			])
			
			followCam.runAction(cameraSequence, completion: {
				self.isReadyToShoot = true
			})
		}
		else {
			// Follow the node
			if let handle = node.childNodeWithName("cameraHandle") {
				let oldRelativePosition = absolutePosition(followCam)
				followCam.removeFromParent()
				
				let nodePosition = absolutePosition(handle)
				if oldRelativePosition != nil && nodePosition != nil {
					followCam.position = CGPoint(
						x: oldRelativePosition!.x - nodePosition!.x,
						y: oldRelativePosition!.y - nodePosition!.y
					)
				}
				
				handle.addChild(followCam)
				moveCamera(CGPoint(x: 0, y: 0), zoom: zoom, duration: 0.5)
			}
		}
	}
	
	func emitSparks(position: CGPoint, color: UIColor? = nil) {
		if let spark = SKEmitterNode(fileNamed: "SparkParticle") {
			spark.particleColorSequence = nil
			spark.particleColor = color ?? spark.particleColor
			spark.position = position
			addChild(spark)
		}
	}
	
	func emitSplash(position: CGPoint) {
		if let splash = SKEmitterNode(fileNamed: "Splash") {
			splash.position = position
			splash.setScale(2)
			addChild(splash)
		}
		
		self.runAction(SKAction.playSoundFileNamed("splash.mp3", waitForCompletion: false))
	}
	
	func shootBall(fromPosition fromPosition: CGPoint, targetPosition: CGPoint, radius: CGFloat = 30) {
		
		if !self.isReadyToShoot { return }	// Only allow one ball at a time
		
		// Make a new node
		ball = SKSpriteNode(imageNamed: "ball1")
		ball?.name = "ball"
		ball?.size.width = 2 * radius
		ball?.size.height = 2 * radius
		ball?.position = fromPosition
		
		// Animate the node
		var ballTextures: [SKTexture] = []
		for i in 1...5 {
			ballTextures.append(SKTexture(imageNamed: "ball\(i)"))
		}
		
		let ballAnimation = SKAction.animateWithTextures(ballTextures, timePerFrame: 0.1)
		ball?.runAction(SKAction.repeatActionForever(ballAnimation))
		
		// Configure physics body
		ball?.physicsBody = SKPhysicsBody(circleOfRadius: radius)
		ball?.physicsBody?.linearDamping = 0.1
		ball?.physicsBody?.angularDamping = 0.5
		ball?.physicsBody?.mass = 0.2
		ball?.physicsBody?.restitution = 0.5
		
		// Categorise the ball
		ball?.physicsBody?.categoryBitMask = NodeCategory.Ball
		ball?.physicsBody?.contactTestBitMask = NodeCategory.All
		ball?.physicsBody?.collisionBitMask = NodeCategory.All - NodeCategory.FlyThrough
		
		// Add smoke
		if let smoke = SKEmitterNode(fileNamed: "Smoke") {
			smoke.targetNode = self
			ball?.addChild(smoke)
		}
		
		// Add camera handle
		let handle = SKSpriteNode(color: UIColor.redColor(), size: CGSize(width: 1, height: 1))
		handle.zPosition = -50
		handle.name = "cameraHandle"
		handle.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 1, height: 1))
		handle.physicsBody?.dynamic = true
		handle.physicsBody?.pinned = true
		handle.physicsBody?.angularDamping = 0.0
		handle.physicsBody?.linearDamping = 0.0
		handle.physicsBody?.mass = 0.0001
		handle.physicsBody?.friction = 0.0
		handle.physicsBody?.categoryBitMask = NodeCategory.None
		handle.physicsBody?.collisionBitMask = NodeCategory.None
		
		ball?.addChild(handle)
		
		
		// Shoot it out!
		self.isReadyToShoot = false
		self.addChild(ball!)
		ball?.physicsBody?.applyImpulse(ballVector(ballPosition: fromPosition, touchPosition: targetPosition, maxLength: 150))
		cannon.runAction(SKAction.playSoundFileNamed("shot.wav", waitForCompletion: false))
		
		// Make the camera follow the ball
		followNode(ball!, zoom: 1.5)
	}
	
	func ballVector(ballPosition ballPosition: CGPoint, touchPosition: CGPoint, maxLength:CGFloat = 150) -> CGVector {
		let distance = touchPosition.distanceFrom(ballPosition)
		let vectorLength = maxLength - maxLength / (distance / maxLength * 3 - 1)
		// print("Distance: \(distance), ball vector strength: \(vectorLength)")
		return CGVector(
			dx: (vectorLength / maxLength) * (touchPosition.x - ballPosition.x),
			dy: (vectorLength / maxLength) * (touchPosition.y - ballPosition.y))
	}
	
	func wobbleBucket(bucket: SKNode, delta: Double) {
		let duration: NSTimeInterval = 0.5
		let moveUp = SKAction.moveBy(CGVector(dx: 0, dy: delta), duration: duration * 1.2)
		moveUp.timingMode = SKActionTimingMode.EaseInEaseOut
		let moveDown = SKAction.moveBy(CGVector(dx: 0, dy: -delta), duration: duration)
		moveDown.timingMode = SKActionTimingMode.EaseInEaseOut
		let wobbleSequence = SKAction.sequence([moveUp, moveDown, SKAction.waitForDuration(duration)])
		bucket.runAction(SKAction.repeatActionForever(wobbleSequence))
	}
	
	func bucketHit(ball: SKNode?) {
		score = score + 1;
		if let label = self["//scoreLabel"].first as? SKLabelNode {
			label.text = "\(score) ball\(score > 1 ? "s" : "") in the bucket!"
			
			// Label size
			let ratio: CGFloat = 1.3
			let scaleUp = SKAction.scaleBy(ratio, duration: 0.1)
			scaleUp.timingMode = SKActionTimingMode.EaseIn
			let scaleDown = SKAction.scaleBy(1/ratio, duration: 0.2)
			scaleDown.timingMode = SKActionTimingMode.EaseOut
			
			// Cancel old actions and reset scale to 1
			label.removeAllActions()
			label.xScale = 1
			label.yScale = 1
			label.runAction(SKAction.sequence([scaleUp, scaleDown]))
		}
		
		self.runAction(SKAction.playSoundFileNamed("plum.wav", waitForCompletion: false))
		ballDisappearanceInfo = BallDestructionInfo(position: absolutePosition(ball!)!, destiny: .BucketLanding)
		ball?.removeFromParent()
		
		// Add some actions and animations
		
		// Background color shift
		if let backgroundNode = self.childNodeWithName("background") as? SKSpriteNode {
			if backgroundNodeColor == nil {
				backgroundNodeColor = backgroundNode.color
			}
			let newColor = UIColor.whiteColor()
			let oldColor = backgroundNodeColor!
			let paintNew = SKAction.colorizeWithColor(newColor, colorBlendFactor: 1, duration: 0)
			let paintOld = SKAction.colorizeWithColor(oldColor, colorBlendFactor: 1, duration: 0.4)
			paintOld.timingMode = SKActionTimingMode.EaseOut
			
			// Cancel unfinished actions and run the new color change
			backgroundNode.removeAllActions()
			backgroundNode.runAction(SKAction.sequence([paintNew, paintOld]))
		}
	}
}
