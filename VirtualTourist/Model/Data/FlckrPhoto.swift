//
//  FlckrPhoto.swift
//  HelloFlickr
//
//  Created by Vui Nguyen on 5/29/19.
//
//  Note: Parts of this file came from Razeware LLC as noted below:
//
/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class FlickrPhoto: Equatable {
  var photoImage: UIImage?
  let photoID: String
  let farm: Int
  let server: String
  let secret: String

  init (photoID: String, farm: Int, server: String, secret: String, photoImage: UIImage? = nil) {
    self.photoID = photoID
    self.farm = farm
    self.server = server
    self.secret = secret

    if let photo = photoImage {
      self.photoImage = photo
    }
  }

  func flickrImageURL(_ size: String = "q") -> URL? {
    if let url =  URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret)_\(size).jpg") {
      return url
    }
    return nil
  }

  static func ==(lhs: FlickrPhoto, rhs: FlickrPhoto) -> Bool {
    return lhs.photoID == rhs.photoID
  }

  enum Error: Swift.Error {
    case invalidURL
    case noData
  }
}
