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
        
        sync()
        
        async()
        
        after()
        
        once()
        once()
    }
    
    func sync() {
        EasyGCD.sync(.global(qos: .background)) {
            print("sync @ background global queue")
        }
    }
    
    func async() {
        EasyGCD.async(EasyGCDQueue.global(.background)) {
            print("async @ background global queue")
        }
        EasyGCD.async {
            print("async @ main queue")
        }
    }
    
    func after() {
        EasyGCD.after(2.0) {
            print("2 seconds later")
        }
        EasyGCD.after(4, queue: .global(qos: .default)) {
            print("4 seconds later")
        }
        EasyGCD.after(DispatchTime.now() + 5, queue: .main) {
            print("6 seconds later")
        }
    }
    
    func once() {
        EasyGCD.once(token: "Once") {
            print("Once")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

