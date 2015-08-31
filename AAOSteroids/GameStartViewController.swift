//
//  GameStartViewController.swift
//  AAOSteroids
//
//  Created by Michael Johnson on 8/29/15.
//  Copyright (c) 2015 BobbingHeads. All rights reserved.
//

import UIKit

class GameStartViewController: UIViewController {

    @IBOutlet weak var ConstantStream: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Create a variable that you want to send
        constantStreamOfBall = ConstantStream.on
        
        // Create a new variable to store the instance of PlayerTableViewController
        let destinationVC = segue.destinationViewController as! GameViewController
    }
    
}
