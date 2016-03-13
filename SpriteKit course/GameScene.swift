//
//  GameScene.swift
//  SpriteKit course
//
//  Created by Karol Pilch on 01/02/2016.
//  Copyright (c) 2016 Karol Pilch. All rights reserved.
//

import SpriteKit

extension CGPoint {
	func distanceFrom (other: CGPoint) -> CGFloat {
		let dx = x - other.x
		let dy = y - other.y
		return sqrt((dx * dx) + (dy * dy))
	}
}

extension SKScene {
	func absolutePosition(node: SKNode) -> CGPoint? {
		var result = node.position
		
		var parent = node.parent
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
		
		static let None: UInt32						= 0
		static let All: UInt32						= UINT32_MAX
	}
	
//	let obstacleCategory: UInt32 =		0b1 << 0	// 1
//	let ballCategory: UInt32 =		0b1 << 1	// 2
//	let pegMask: UInt32 =			0b1 << 2	// 4
//	let squareMask: UInt32 =	0b1 << 3	// 8
//	let sparkyMask: UInt32 =  0b1 << 4	// 16
//	
//	let orangeNode: UInt32 =	0b1 << 5	// 32
//	let blueNode: UInt32 =		0b1 << 6	// 64
	
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
	
	var lonelyLabel: SKLabelNode!
	var yellowBlock: SKSpriteNode!
	var cannon: SKSpriteNode!
	var cannonPosition = CGPointZero
	
	var touchLocation: CGPoint = CGPointZero
	
	

	
	func ballVector(ballPosition ballPosition: CGPoint, touchPosition: CGPoint, maxLength:CGFloat = 150) -> CGVector {
		let distance = touchPosition.distanceFrom(ballPosition)
		let vectorLength = maxLength - maxLength / (distance / maxLength * 3 - 1)
		// print("Distance: \(distance), ball vector strength: \(vectorLength)")
		return CGVector(
			dx: (vectorLength / maxLength) * (touchPosition.x - ballPosition.x),
			dy: (vectorLength / maxLength) * (touchPosition.y - ballPosition.y))
	}
	
	func startYellowBlockActions() {
		// Set the anchor point on the bottom
		yellowBlock.anchorPoint = CGPoint(x: 0.5, y: 0)
		
		// Scale a bit to make it look like it's walking
		let scaleDuration = 0.6	// Speed of wobbling
		let scaleUp = (
			x: SKAction.scaleXTo(0.7, duration: scaleDuration),
			y: SKAction.scaleYTo(1.3, duration: scaleDuration)
		)
		let scaleDown = (
			x: SKAction.scaleXTo(1, duration: scaleDuration),
			y: SKAction.scaleYTo(1, duration: scaleDuration)
		)
		for scale in [scaleUp, scaleDown] {
			scale.x.timingMode = SKActionTimingMode.EaseInEaseOut
			scale.y.timingMode = SKActionTimingMode.EaseInEaseOut
		}
		
		yellowBlock.runAction(SKAction.repeatActionForever(SKAction.sequence([scaleUp.x, scaleDown.x])))
		yellowBlock.runAction(SKAction.repeatActionForever(SKAction.sequence([scaleUp.y, scaleDown.y])))
		
		// Figure out bottom left and right corners of the scene
		let halfWidth = yellowBlock.size.width / 2.0
		var bottomLeft = CGPoint(x: halfWidth, y: 0)
		var bottomRight = CGPoint(x: self.size.width - halfWidth , y: 0)
		
		if let leftWall = self.childNodeWithName("leftWall") as? SKSpriteNode {
			bottomLeft.x += leftWall.size.width * (1 - leftWall.anchorPoint.x)
		}
		if let rightWall = self.childNodeWithName("rightWall") as? SKSpriteNode {
			bottomRight.x -= rightWall.size.width * rightWall.anchorPoint.x
		}
		if let floor = self.childNodeWithName("floor") as? SKSpriteNode {
			let deltaY = floor.size.height * (1 - floor.anchorPoint.y)
			bottomLeft.y += deltaY
			bottomRight.y += deltaY
		}
		
		// Move to the bottom left
		yellowBlock.position = bottomLeft
		
		// Make it move left and right
		let moveDuration = 4.0
		let moveRight = SKAction.moveTo(bottomRight, duration: moveDuration)
		moveRight.timingMode = SKActionTimingMode.EaseInEaseOut
		
		let moveLeft = SKAction.moveTo(bottomLeft, duration: moveDuration)
		moveLeft.timingMode = SKActionTimingMode.EaseInEaseOut
		yellowBlock.runAction(SKAction.repeatActionForever(SKAction.sequence([moveRight, moveLeft])))
	}
	
	override func didMoveToView(view: SKView) {
		// Need to set up self as the contact delegate
		self.physicsWorld.contactDelegate = self;
		
		// Connect nodes to our variables
		cannon = self.childNodeWithName("//cannon") as! SKSpriteNode
		if let pos = absolutePosition(cannon) { cannonPosition = pos }
		yellowBlock = self.childNodeWithName("yellowBlock") as! SKSpriteNode
		lonelyLabel = self.childNodeWithName("lonelyLabel") as! SKLabelNode
		
		// Process nodes in the scene
		for nodeName in ["rotatingSquare", "orangePeg", "bluePeg", "leftWall", "rightWall", "floor", "yellowBlock"] {
			enumerateChildNodesWithName(nodeName, usingBlock: { (node: SKNode, ptr: UnsafeMutablePointer<ObjCBool>) -> Void in
				if node.physicsBody != nil {
					switch nodeName {
						case "rotatingSquare":
							node.physicsBody!.categoryBitMask = NodeCategory.Obstacle
						case "orangePeg":
							node.physicsBody!.categoryBitMask = NodeCategory.Destructible | NodeCategory.Sparks | NodeCategory.Orange
						case "bluePeg":
							node.physicsBody!.categoryBitMask = NodeCategory.Destructible | NodeCategory.Sparks | NodeCategory.Blue
						case "leftWall", "rightWall", "floor":
							node.physicsBody!.categoryBitMask = NodeCategory.Obstacle
						case "yellowBlock":
							node.physicsBody!.categoryBitMask = NodeCategory.Obstacle
						default: break
					}
				}
			})
		}
		
		// Start the actions we defined in code
		startYellowBlockActions()
	}
	
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if let firstTouch = touches.first {
			touchLocation = firstTouch.locationInNode(self)
			
			let fadeOut = SKAction.sequence([
				SKAction.fadeOutWithDuration(0.5),
				SKAction.removeFromParent()]);	// This actually doesn't delete it - it just disappears from the parent.
			
			lonelyLabel.runAction(fadeOut)
		}
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		
		// If I understand correctly, the code below creates a new scene and takes the ball from it every time... Hmm.
		if let ball = SKScene(fileNamed: "Ball")?.childNodeWithName("ball") {
			// Insert the ball to the scene
			ball.removeFromParent()
			self.addChild(ball)
			
			// Move it to the base of the cannon
			let cannonPosition = absolutePosition(cannon)!
			ball.position = cannonPosition
			ball.physicsBody?.categoryBitMask = NodeCategory.Ball
			
			// Shoot it out (instead of just dropping)
			if let touchPosition = touches.first?.locationInNode(self) {
				ball.physicsBody?.applyImpulse(ballVector(ballPosition: cannonPosition, touchPosition: touchPosition))
			}
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
	}

	
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
		
		let otherMask = other.categoryBitMask
		
		if otherMask & NodeCategory.Obstacle != 0 {
			print("Hit obstacle.")
		}
		
		if otherMask & NodeCategory.Destructible != 0 {
			other.node?.removeFromParent()
		}
		
		if otherMask & NodeCategory.Ball != 0 {
			// Other ball hit: Emit sparks and remove both
			let whiteColor = UIColor(white: 1, alpha: 1)
			ball.node?.removeFromParent()
			other.node?.removeFromParent()
			
			emitSparks(contact.contactPoint, color: whiteColor)
		}
		
		if otherMask & NodeCategory.Sparks != 0 {
			// Sparking node contact
			
			// See if the node has a colour category
			let color: UIColor?
			if otherMask & NodeCategory.Orange != 0 { color = orangeColor }
			else if otherMask & NodeCategory.Blue != 0 { color = blueColor }
			else { color = nil }
			
			emitSparks(contact.contactPoint, color: color)
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
}
