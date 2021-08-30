//
//  BaseService.swift
//  toktiv
//
//  Created by Developer on 12/11/2020.
//

import UIKit
import Alamofire
import MBProgressHUD


class Logger: NSObject {
    class func print(_ object:Any) {
        Swift.print(object)
    }
}

public typealias ServiceCompletionHandler = (NSDictionary?, Error?, Data? ) -> ()

class BaseService: NSObject {
    @objc public class func post(_ urlString: String, query: [String:String]?, headers: [String : String]?, body: Data?, bodyInArray: [[String : Any]]? = nil, completionHandler: @escaping ServiceCompletionHandler) {
        makeRequest(with: urlString, method: .post, query: query, headers: headers, body: body,bodyInArray:bodyInArray, completionHandler: completionHandler)
    }
    
    @objc public class func postWithoutQueryParameters(_ urlString: String, query: [String:String]?, headers: [String : String]?, body: Data?, completionHandler: @escaping ServiceCompletionHandler) {
        makeRequest(with: urlString, method: .post, query: query, headers: headers, body: body, completionHandler: completionHandler)
    }
    
    @objc public class func getWithoutQueryParameters(_ urlString: String, query: [String:String]?, headers: [String : String]?, body: Data?, completionHandler: @escaping ServiceCompletionHandler) {
        makeRequest(with: urlString, method: .get, query: query, headers: headers, body: body, completionHandler: completionHandler)
    }
    
    class func makeRequest(with urlString:String, method: HTTPMethod = .get, query: [String:String]? = nil, headers: [String : String]? = nil, body: Data? = nil, bodyInArray: [[String : Any]]? = nil, completionHandler: @escaping ServiceCompletionHandler) {
        
        let defaultQuery = query
        let completeUrl:String
        
        var params: [String] = []
        defaultQuery?.forEach { (key: String, value: String) in
            let param = "\(key)=\(value)"
            params.append(param)
        }
        
        //        if let query = query {
        //            query.forEach({ (key: String, value: String) in
        //                let param = "\(key)=\(value)"
        //                params.append(param)
        //            })
        //        }
        
        
        let queryString = params.joined(separator: "&")
        if queryString.count > 0 {
            completeUrl = "\(urlString)?\(queryString)"
        }
        else {
            completeUrl = urlString
        }
        
        
        guard let url = URL(string: completeUrl) else {
            completionHandler(nil, nil, nil)
            return
        }
        var request = URLRequest(url: url)
        
        if let headers = headers {
            headers.forEach({ (key: String, value: String) in
                request.setValue(value, forHTTPHeaderField: key)
            })
        }
        
        //Add body
        if let body = body {
            request.httpBody = body //body.data(using: .utf8)//bodyData as Data
        }
        
        
        request.httpMethod = method.rawValue
        
        Logger.print("REQUEST\n")
        Logger.print("URL - \(completeUrl)\n")
        if let body = body {
            Logger.print("BODY - \(String(data: body, encoding: .utf8) ?? "")\n")
        }
        
        if let header = headers {
            Logger.print("HEADER - \(header)\n")
        }
        
        AF.request(request)
            .validate(statusCode: 200..<300)
            .responseJSON { (response: DataResponse<Any, AFError>) in
                if let data = response.data {
                    Logger.print("BODY - \(String(data:data, encoding:.utf8) ?? "Unknown")\n")
                }
                
                switch response.result {
                case .success(let value):
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        completionHandler(value as? NSDictionary, nil, response.data)
                    }
                case .failure:
                    let skipRefreshSchemes = [""]
                    let filteredSchemes = skipRefreshSchemes.filter({ (scheme:String) -> Bool in
                        urlString.contains(scheme)
                    })
                    
                    if response.response?.statusCode == 401 && filteredSchemes.isEmpty {
                        
                    }
                    
                    if let httpResponse = response.response{
                        Logger.print("CODE - \(httpResponse.statusCode)\n")
                        let errorTemp = NSError(    domain:"", code:httpResponse.statusCode, userInfo:nil)
                        if let data = response.data, let string = String(data:data, encoding:.utf8) {
                            Logger.print("\(string)")
                            let dict = convertToDictionary(text: string)
                            if let value = dict?.first as NSDictionary? {
                                completionHandler(value, errorTemp, response.data)
                            }
                            else {
                                completionHandler(nil, errorTemp, response.data)
                            }
                        }
                        else {
                            completionHandler(nil, errorTemp, response.data)
                        }
                    }
                    else
                    {
                        completionHandler(nil, response.error, nil)
                    }
                }
            }
    }
    
    @objc public class func upload(imgData:Data, with urlString:String, contentType: String, filename: String, progressHud: MBProgressHUD, completionHandler: @escaping ServiceCompletionHandler)
    {
        AF.upload(multipartFormData:
        { multipartFormData in
            
            multipartFormData.append(imgData, withName: "attachment_file", fileName: filename, mimeType: contentType)
//            for (key, value) in parameters
//            {
//                    multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
//            } //Optional for extra parameters
        }, to: NetworkURLs.POST_CHAT_ATTACHMENT)
        .uploadProgress
        { progress in
            progressHud.progress = Float(progress.fractionCompleted)

            print("Upload Progress: \(progress.fractionCompleted)")
            
        }
        .responseJSON
            { (response: DataResponse<Any, AFError>) in
                if let data = response.data {
                    Logger.print("BODY - \(String(data:data, encoding:.utf8) ?? "Unknown")\n")
                }
                
                switch response.result {
                case .success(let value):
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        completionHandler(value as? NSDictionary, nil, response.data)
                    }
                case .failure(let error):
                    progressHud.hide(animated: true)
                    let skipRefreshSchemes = [""]
                    let filteredSchemes = skipRefreshSchemes.filter({ (scheme:String) -> Bool in
                        urlString.contains(scheme)
                    })
                    
                }
            }
    }
    
    class func convertToDictionary(text: String) -> [[String: Any]]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
            } catch {
                print(error.localizedDescription)
            }
        }
        
        return nil
    }
    
}
