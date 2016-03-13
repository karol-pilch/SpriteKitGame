//
//  GameViewController.swift
//  SpriteKit course
//
//  Created by Karol Pilch on 01/02/2016.
//  Copyright (c) 2016 Karol Pilch. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let scene = GameScene(fileNamed:"MainMenu") {
			// Configure the view.
			let skView = self.view as! SKView
			skView.showsFPS = true
			skView.showsNodeCount = true
			
			/* Sprite Kit applies additional optimizations to improve rendering performance */
			// KP: This makes the view draw without taking siblings order into the account.
			skView.ignoresSiblingOrder = true
			
			/* Set the scale mode to scale to fit the window */
			// .AspectFill - The scene will fill the screen with aspect ratio preserved. Cropped if necessary.
			// .AspectFit - The scene will be shown in the entirety, with aspect ratio preserved. Letterboxed if necessary.
			// .Fill - Scales the content to fit the screen. Aspect ratio is not preserved.
			// .ResizeFill - Scene is not scaled at all. No idea what it actually does.
			scene.scaleMode = .AspectFit
			
			skView.presentScene(scene)
		}
	}
	
	override func shouldAutorotate() -> Bool {
		return true
	}
	
	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
			return .AllButUpsideDown
		} else {
			return .All
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Release any cached data, images, etc that aren't in use.
	}
	
	override func prefersStatusBarHidden() -> Bool {
		return true
	}
}
