//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Isaac Albets Ramonet on 27/01/16.
//  Copyright © 2016 udacity. All rights reserved.
//

import Foundation

class  FlickrClient: NSObject {
    
    typealias CompletionHandler = (result: AnyObject!, error: NSError?) -> Void
    
    var session: NSURLSession
    
    override init(){
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // MARK: - Task for GET
    func taskForGet(resource: String, parameters: [String: AnyObject], completionHandler: CompletionHandler) -> NSURLSessionDataTask{
        
        let urlString = Constants.BaseUrlSSL + resource + FlickrClient.escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, downloadError) in
        
            if let error = downloadError {
                let newError = FlickrClient.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            }
            
            guard let data = data else {
                print("Request returned no data")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let _ = response as? NSHTTPURLResponse {
                    completionHandler(result: nil, error: downloadError)
                } else if let _ = response {
                    completionHandler(result: nil, error: downloadError)
                } else {
                    completionHandler(result: nil, error: downloadError)                }
                return
            }
            
            let parsedResult: AnyObject!
            do{
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                completionHandler(result: parsedResult, error: nil)
            } catch _ {}
            
        }
        task.resume()
        
        return task
    }

    
    // MARK: - Task for POST
    
    
    // MARK: - Helpers
    
    /// Helper method for parsing JSON data
    class func parseJSONWithCompletionHAndler(data: NSData, completionHandler: CompletionHandler) {
        var parsedError: NSError? = nil
        let parsedResult: AnyObject?
        do{
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError{
            parsedError = error
            parsedResult = nil
        }
        
        if let error = parsedError{
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    /// URL encoding a dictionary into a parameter string
    class func escapedParameters(parameters: [String: AnyObject]) -> String {
        var urlVars = [String]()
        for (key, value) in parameters{
            
            let stringValue = "\(value)"
            
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            if let unwrappedEscapedValue = escapedValue {
                urlVars += [key + "=" + "\(unwrappedEscapedValue)"]
            } else {
               print("Warning: trouble escaping string \(stringValue)")
            }
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
//    func escapedParams(parameters: [String: AnyObject]) -> String{
//        var urlVars = [String]()
//        for (mogly, balu) in parameters{
//            let stringBalu = "\(balu)"
//            let escapedBalu = stringBalu.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
//            urlVars += [mogly + "=" + "\(escapedBalu!)"]
//        }
//        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
//    }
    
    /// Make a better error based on the status_message
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError{
        if data == nil {
            return error
        }
        
        do{
            let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
            
            if let parsedResult = parsedResult as? [String: AnyObject], errorMessage = parsedResult[FlickrClient.Keys.ErrorStatusMessage] as? String{
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                return NSError(domain: "FlickrDB Error", code: 1, userInfo: userInfo)
            }
        } catch _ {}
        
        return error
    }
    
    // MARK: - Shared Instance
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
}

