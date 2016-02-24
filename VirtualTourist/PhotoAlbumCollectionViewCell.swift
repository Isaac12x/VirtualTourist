//
//  PhotoAlbumCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Isaac Albets Ramonet on 28/01/16.
//  Copyright © 2016 udacity. All rights reserved.
//

import Foundation
import UIKit

class PhotoAlbumCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var photoAlbumImage: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
        
        override func awakeFromNib() {
            activityIndicatorView.hidesWhenStopped = true
            activityIndicatorView.color = UIColor.blackColor()
        
        }
}