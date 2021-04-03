//
//  ViewController.swift
//  Player
//
//  Created by Ahmed Yasser on 4/3/21.
//  Copyright © 2021 Ahmed Yasser. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func play(_ sender: UIButton) {
        guard let url = URL(string: "https://filesamples.com/samples/audio/mp3/sample4.mp3") else { return }
        let player = AYPlayer(url: url)
        player.play()
        player.delegate = self
    }
}

extension ViewController: AYPlayerDelegate {
    func currentTime(_ inSeconds: Float64, _ totalFormatted: String) {
        print("Current Time: \(inSeconds), Total Formatted: \(totalFormatted)")
    }
}
