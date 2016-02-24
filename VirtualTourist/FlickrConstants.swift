//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Isaac Albets Ramonet on 27/01/16.
//  Copyright © 2016 udacity. All rights reserved.
//

import Foundation


extension FlickrClient{
    struct Constants {
        // MARK: - URLs
        static let ApiKey = "ab4cb0d15edaf496907a0039eba7bf41"
        static let ApiKeySecret = "677e133c0eee103a"
        static let BaseUrlSSL = "https://api.flickr.com/services/rest/"
    }
    
    struct Methods {
        
        // MARK: - Methods
        static let FindPhotos = "flickr.photos.search"
        
        // MARK: - Methods for getting location
        static let FindByLocation = "flickr.photos.geo.photosForLocation"
        static let FindByLatLon = "flickr.places.findByLatLon"
        
        // MARK: - Methods for getting information
        static let GetAllContexts = "flickr.photos.getAllContexts"
        static let GetInfo = "flickr.photos.getInfo"
    
    }
    
    struct ParameterKeys {
        static let ApiKey = "api_key"
        static let Lat = "lat"
        static let Long = "long"
        static let DataFormatFormat = "format"
        static let CallBackKey = "nojsoncallback"
        static let Extras = "extras"
    }
    
    struct ParameterValues {
        static let Extras = "url_m"
        static let SafeSearch = "1"
        static let DataFormat = "json"
        static let CallBack = "1"
    }


    
    struct Keys {
        static let ErrorStatusMessage = "message"
        static let PhotoI = "photo"
    }
    
//    struct Keys {
//        static let ErrorStatusMessage = "status_message"
//    }
}

