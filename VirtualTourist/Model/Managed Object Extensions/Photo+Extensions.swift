//
//  Photo+Extensions.swift
//  VirtualTourist
//
//  Created by Vui Nguyen on 6/6/19.
//  Copyright © 2019 SunfishEmpire. All rights reserved.
//

import Foundation
import CoreData

extension Photo {
  public override func awakeFromInsert() {
    super.awakeFromInsert()
    creationDate = Date()
  }
}
