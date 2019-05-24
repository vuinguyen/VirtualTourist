//
//  PhotoRequest.swift
//  VirtualTourist
//
//  Created by Vui Nguyen on 5/23/19.
//  Copyright © 2019 SunfishEmpire. All rights reserved.
//

import UIKit

class PhotoRequest {

  static func getPics(_ resultsPageNumber: Int = 0) -> ([UIImage]?, Int?) {
    var pics = [UIImage]()
    var imageName: String = "Placeholder"
    var imageNumber: Int

    switch resultsPageNumber {
    case 1:
      imageNumber = 2
    case 2:
      imageNumber = 3
    case 3:
      imageNumber = 4
    case 4:
      imageNumber = 1
    default:
      imageNumber = 1
    }

    imageName += String(imageNumber)
    for _ in 0...11 {
      if let image = UIImage(named: imageName) {
        pics.append(image)
      }
    }

    return (pics, imageNumber)
  }
  
}
