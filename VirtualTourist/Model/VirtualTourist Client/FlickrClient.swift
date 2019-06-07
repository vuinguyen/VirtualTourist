//
//  FlickrClient.swift
//  HelloFlickr
//
//  Created by Vui Nguyen on 5/26/19.
//  Copyright © 2019 SunfishEmpire. All rights reserved.
//

import UIKit

class FlickrClient {


  enum Error: Swift.Error {
    case unknownAPIResponse
    case generic
  }

  class func getRandomPageNum(totalPicsAvailable: Int, maxNumPicsDisplayed: Int) -> Int {
    let numPages = totalPicsAvailable / maxNumPicsDisplayed
    let randomPageNum = Int.random(in: 1...numPages)
    print("totalPicsAvailable is \(totalPicsAvailable)")
    print("numPages is \(numPages)")
    print("randomPageNum is \(randomPageNum)")
    return randomPageNum
  }

  class func getFlickrPhotos(latitude: Double, longitude: Double,
                             totalNumPicsAvailable: Int = 0,
                             updatedNumPicsToDisplay: Int = 12,
                             maxNumPicsDisplayed: Int = 12,
                             completion: @escaping ([FlickrPhoto]?, Int?, Error?) -> Void) {
    // let's calculate how many pages we could get, and randomly
    // select a pageNum
    // we definitely want to save off the new totalNumPics we get for next time
    let pageNum = totalNumPicsAvailable > 0 ?
      getRandomPageNum(totalPicsAvailable: totalNumPicsAvailable, maxNumPicsDisplayed: maxNumPicsDisplayed) : 1

    let radius = 20
    let perPage = updatedNumPicsToDisplay // but we only want to download just the number of pictures we need to display
    // in the updated display
    let searchURLString = "https://www.flickr.com/services/rest/?method=flickr.photos.search" +
      "&api_key=\(APIKeys.ApplicationID)" +
      "&lat=\(latitude)" +
      "&lon=\(longitude)" +
      "&radius=\(radius)" +
      "&per_page=\(perPage)" +
      "&page=\(pageNum)" +
    "&format=json&nojsoncallback=1"

    guard let searchURL = URL(string: searchURLString) else {
      return
    }
    let searchRequest = URLRequest(url: searchURL)

    let task = URLSession.shared.dataTask(with: searchRequest) { (data, response, error) in
      if let error = error {
        print("there is an error!: \(error)")
        completion(nil, nil, Error.generic)
        return
      }

      guard let data = data else {
        return
      }

      print("we got a response back!: \(data)")

      do {
        guard
          let resultsDictionary = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject],
          let stat = resultsDictionary["stat"] as? String
          else {
            DispatchQueue.main.async {
              completion(nil, nil, Error.unknownAPIResponse)
              print("error in getting data")

            }
            return
        }

        // check value of stat

        switch (stat) {
        case "ok":
          print("Results processed OK")
        case "fail":
          DispatchQueue.main.async {
            print("error in parsing stat")
            completion(nil, nil, Error.generic)
          }
          return
        default:
          DispatchQueue.main.async {
            print("error in parsing stat, in default")
            completion(nil, nil, Error.unknownAPIResponse)
          }
          return
        }

        guard
          let photosContainer = resultsDictionary["photos"] as? [String: AnyObject],
          let photosReceived = photosContainer["photo"] as? [[String: AnyObject]],
          let updatedTotalNumPics:Int = Int((photosContainer["total"] as? String)!)
          else {
            DispatchQueue.main.async {
              print("photos not in proper format")
              completion(nil, nil, Error.unknownAPIResponse)
            }
            return
        }

        let flickrPhotos: [FlickrPhoto] = photosReceived.compactMap { photoObject in
          guard
            let photoID = photoObject["id"] as? String,
            let farm = photoObject["farm"] as? Int,
            let server = photoObject["server"] as? String,
            let secret = photoObject["secret"] as? String
            else {
              return nil
          }

          let flickrPhoto = FlickrPhoto(photoID: photoID, farm: farm, server: server, secret: secret)
          return flickrPhoto
        } // end of map here


        DispatchQueue.main.async {
          print("successfully returned array of flickrPhotos!")
          completion(flickrPhotos, updatedTotalNumPics, nil)
        }

      } catch {
        print("error yo!")
        return
      }

    }
    task.resume()
  }

  class func downloadImage(imageURL: URL?, completion: @escaping (Data?, Error?) -> Void) {

    guard let imageURL = imageURL else {
      DispatchQueue.main.async {
        completion(nil, Error.generic)
      }
      return
    }
    
    let request = URLRequest(url: imageURL)
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      DispatchQueue.main.async {
        completion(data, nil)
      }
    }
    task.resume()
  }
}
