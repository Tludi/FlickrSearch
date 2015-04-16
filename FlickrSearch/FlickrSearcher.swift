//
//  FlickrSearcher.swift
//  flickrSearch
//
//  Created by Richard Turton on 31/07/2014.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

import Foundation
import UIKit

let apiKey = "7ad9dc24b93affb369df485083893e9e"

// Create a struct for the search term and results
struct FlickrSearchResults {
  let searchTerm : String
  let searchResults : [FlickrPhoto]
}

// create and initialize a photo object to inject data from the Flickr API
class FlickrPhoto : Equatable {
  var thumbnail : UIImage?
  var largeImage : UIImage?
  let photoID : String
  let farm : Int
  let server : String
  let secret : String
  
  init (photoID:String,farm:Int, server:String, secret:String) {
    self.photoID = photoID
    self.farm = farm
    self.server = server
    self.secret = secret
  }
  
  func flickrImageURL(size:String = "m") -> NSURL {
    return NSURL(string: "http://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret)_\(size).jpg")!
  }
  
  func loadLargeImage(completion: (flickrPhoto:FlickrPhoto, error: NSError?) -> Void) {
    let loadURL = flickrImageURL(size: "b")
    let loadRequest = NSURLRequest(URL:loadURL)
    NSURLConnection.sendAsynchronousRequest(loadRequest,
      queue: NSOperationQueue.mainQueue()) {
        response, data, error in
        
        if error != nil {
          completion(flickrPhoto: self, error: error)
          return
        }
        
        if data != nil {
          let returnedImage = UIImage(data: data)
          self.largeImage = returnedImage
          completion(flickrPhoto: self, error: nil)
          return
        }
        
        completion(flickrPhoto: self, error: nil)
    }
  }
  
  func sizeToFillWidthOfSize(size:CGSize) -> CGSize {
    if thumbnail == nil {
      return size
    }
    
    let imageSize = thumbnail!.size
    var returnSize = size
    
    let aspectRatio = imageSize.width / imageSize.height
    
    returnSize.height = returnSize.width / aspectRatio
    
    if returnSize.height > size.height {
      returnSize.height = size.height
      returnSize.width = size.height * aspectRatio
    }
    
    return returnSize
  }
  
} // end FlickrPhoto

func == (lhs: FlickrPhoto, rhs: FlickrPhoto) -> Bool {
  return lhs.photoID == rhs.photoID
}

class Flickr {
  
  let processingQueue = NSOperationQueue()
  
  // search Flickr for the search term
  func searchFlickrForTerm(searchTerm: String, completion : (results: FlickrSearchResults?, error : NSError?) -> Void){
    
    // set the URL for Flickr with the search term
    let searchURL = flickrSearchURLForSearchTerm(searchTerm)
    
    // actually do the request to the Flickr URL
    let searchRequest = NSURLRequest(URL: searchURL)
    NSURLConnection.sendAsynchronousRequest(searchRequest, queue: processingQueue) {response, data, error in
      if error != nil {
        completion(results: nil,error: error)
        return
      }
      // set variable if there is an error
      var JSONError : NSError?
      // create a dictionary of the results if no error
      // results included in a JSON object
      let resultsDictionary = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions(0), error: &JSONError) as? NSDictionary
      // if the error variable is not nil, not sure what it does here
      if JSONError != nil {
        completion(results: nil, error: JSONError)
        return
      }
      // check the resultsDictionary stat - send a message to the console
      switch (resultsDictionary!["stat"] as! String) {
      // if stat is ok, print to the console
      case "ok":
        println("Results processed OK")
      // if stat fails, print error to console
      case "fail":
        let APIError = NSError(domain: "FlickrSearch", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:resultsDictionary!["message"]!])
        completion(results: nil, error: APIError)
        return
      // set the default to print unknown error to the console if neither ok or fail
      default:
        let APIError = NSError(domain: "FlickrSearch", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Uknown API response"])
        completion(results: nil, error: APIError)
        return
      }
      
      let photosContainer = resultsDictionary!["photos"] as! NSDictionary
      let photosReceived = photosContainer["photo"] as! [NSDictionary]
      
      // process each photo into dictionary
      let flickrPhotos : [FlickrPhoto] = photosReceived.map {
        photoDictionary in
        
        let photoID = photoDictionary["id"] as? String ?? ""
        let farm = photoDictionary["farm"] as? Int ?? 0
        let server = photoDictionary["server"] as? String ?? ""
        let secret = photoDictionary["secret"] as? String ?? ""
        
        let flickrPhoto = FlickrPhoto(photoID: photoID, farm: farm, server: server, secret: secret)
        
        let imageData = NSData(contentsOfURL: flickrPhoto.flickrImageURL())
        flickrPhoto.thumbnail = UIImage(data: imageData!)
        
        return flickrPhoto
      }
      // send a block to be processed in the queue
      dispatch_async(dispatch_get_main_queue(), {
        completion(results:FlickrSearchResults(searchTerm: searchTerm, searchResults: flickrPhotos), error: nil)
      })
    }
  }
  
  // set the URL for searching Flickr
  private func flickrSearchURLForSearchTerm(searchTerm:String) -> NSURL {
    
    // make sure the Search Term is encoded properly
    let escapedTerm = searchTerm.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
    
    // set the API address for searching Flickr with the escaped searchTerm
    let URLString = "https://api.flickr.com/services/rest/?method=flickr.photos.getRecent&api_key=\(apiKey)&text=\(escapedTerm)&per_page=20&format=json&nojsoncallback=1"
    // return the proper address with the search term
    return NSURL(string: URLString)!
  }
  
  
}
