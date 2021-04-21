//
//  AppDelegate.swift
//  ContinuityCamera
//
//  Created by Philipp on 21.04.21.
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        print("applicationWillResignActive")
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        print("applicationWillBecomeActive")
    }
}
