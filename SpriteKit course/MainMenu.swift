//
//  MainMenu.swift
//  SpriteKit course
//
//  Created by Karol Pilch on 19/02/2016.
//  Copyright © 2016 Karol Pilch. All rights reserved.
//

import SpriteKit

class MainMenu: SKScene {
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if let game = GameScene(fileNamed: "GameScene") {
			game.scaleMode = .AspectFill
			
			let transition = SKTransition.crossFadeWithDuration(0.6)
			
			self.view?.presentScene(game, transition: transition)
		}
	}
}
