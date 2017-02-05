//
//  ViewController.swift
//  TorXPCExample
//
//  Created by Chris Ballinger on 1/29/17.
//  Copyright © 2017 ChatSecure. All rights reserved.
//

import Cocoa
import TorXPCInterface

class ViewController: NSViewController {
    
    var tor: TorXPCServiceManager? {
        get {
            guard let appDelegate = NSApplication.shared().delegate as? AppDelegate else {
                return nil
            }
            return appDelegate.tor
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        startButtonPressed(self)
            }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    @IBAction func stopButtonPressed(_ sender: Any) {
        guard let tor = self.tor else { return }
        tor.teardown()
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        guard let tor = self.tor else { return }
        tor.setup(withInternalPort: 5269, externalPort: 5269, serviceDirectoryName: "test")
    }

}

