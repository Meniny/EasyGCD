//
//  ViewController.swift
//  Sample
//
//  Created by Meniny on 2017-07-19.
//  Copyright © 2017年 Meniny. All rights reserved.
//

import UIKit
import EasyGCD

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        syncActions()
        
        asyncActions()
        
        afterActions()
        
        onceActions()
        onceActions()
    }
    
    func syncActions() {
        sync {
            print("sync @ default global queue 1")
        }
        
        global(.synchronously) {
            print("sync @ default global queue 2")
        }
        
        EasyGCD.sync(.global(qos: .background)) {
            print("sync @ background global queue")
        }
    }
    
    func asyncActions() {
        
        async {
            print("async @ main queue 1")
        }
        
        main {
            print("async @ main queue 2")
        }
        
        EasyGCD.async(EasyGCDQueue.global(.background)) {
            print("async @ background global queue")
        }
        
        EasyGCD.async {
            print("async @ main queue 3")
        }
    }
    
    func afterActions() {
        after(1.0) {
            print("1 seconds later")
        }
        
        EasyGCD.after(2.0) {
            print("2 seconds later")
        }
        EasyGCD.after(4, queue: .global(qos: .default)) {
            print("4 seconds later")
        }
        EasyGCD.after(DispatchTime.now() + 6, queue: .main) {
            print("6 seconds later")
        }
    }
    
    func onceActions() {
        once("Once1") { 
            print("Once1")
        }
        
        EasyGCD.once(token: "Once2") {
            print("Once2")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

