//
//  Constants.swift
//  Map
//
//  Created by maika on 1/19/20.
//  Copyright © 2020 maika. All rights reserved.
//

import Foundation
var apikey = "d52b6349ab80d0cbf8f731c8f27b5f8f"

func flickerUrl(forApiKey key:String, withAnnotation annotation: DroppablePin,numberOfPhotos num: Int) -> String{
    return "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apikey)&lat=\(annotation.coordinate.latitude)8&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(num)&format=json&nojsoncallback=1"
   
}
