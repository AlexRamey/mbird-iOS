//
//  PlayPauseView.swift
//  iOS Client
//
//  Created by Jonathan Witten on 3/24/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class PlayPauseView: UIView, LoadableNibByClassName {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var tapRecognizer: UITapGestureRecognizer!
}
