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

  class func getPhotoList(latitude: Double, longitude: Double,
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
        return
      }

      guard let data = data else {
        return
      }

      print("we got a response back!: \(data)")

      // parse into Results, which contains photos (json objects)
      // from each photo json object, build a URL and grab data from the url
      // (this downloads the picture)
      // and then create an image object (UIImage) out of the downloaded data
      // (place into a Photo class?)
      // run completion handler of array of Photo objects
      // ie reload collection view with new data

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

          guard
            let url = flickrPhoto.flickrImageURL(),
            let imageData = try? Data(contentsOf: url as URL)
            else {
              return nil
          }

          if let image = UIImage(data: imageData) {
            flickrPhoto.photoImage = image
            return flickrPhoto
          } else {
            return nil
          }

        } // end of map here


        DispatchQueue.main.async {
          print("successfully downloaded pics!")
          completion(flickrPhotos, updatedTotalNumPics, nil)
        }

      } catch {
        print("error yo!")
        return
      }

    }
    task.resume()

    /* https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=64e233835212207bf629d1cf4e11706f&lat=42.51089531399634&lon=-96.40061478111414&radius=20&per_page=12&page=2&format=json&nojsoncallback=1
     */


  }


}
