//
//  AppDelegate.swift
//  TorXPCExample
//
//  Created by Chris Ballinger on 1/29/17.
//  Copyright © 2017 ChatSecure. All rights reserved.
//

import Cocoa
import TorXPCInterface

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let tor = TorXPCServiceManager()


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

