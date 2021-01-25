//
//  PlaylistAddNewViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 25.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class PlaylistAddNewViewController: UIViewController, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "affirmationCell", for: indexPath as IndexPath) as! AffirmationTableViewCell
        return cell
    }
    
    func addSubliminal(text: String) {
        print(text)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
}
