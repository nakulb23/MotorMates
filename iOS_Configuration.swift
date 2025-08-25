//
//  Constants.swift
//  MotorMates
//
//  Configuration for MotorMates API connection
//

import Foundation

struct Constants {
    // Using the same server as GolfSwingAI
    static let baseURL = "https://golfai.duckdns.org:8443"
    
    struct API {
        // MotorMates endpoints
        static let motormates = "/motormates"
        static let health = "\(motormates)/health"
        static let testConnection = "\(motormates)/test-ios"
        static let appUpdates = "\(motormates)/app-updates"
        
        // Authentication
        static let register = "\(motormates)/auth/register"
        static let login = "\(motormates)/auth/login"
        
        // Posts
        static let postsFeed = "\(motormates)/posts/feed"
        static let createPost = "\(motormates)/posts"
        
        // Routes
        static let discoverRoutes = "\(motormates)/routes/discover"
        static let createRoute = "\(motormates)/routes"
        
        // Garage
        static let userGarage = "\(motormates)/garage"
        static let addCar = "\(motormates)/garage/cars"
        
        // Users
        static let userProfile = "\(motormates)/users"
    }
    
    // Headers for API requests
    static let headers = [
        "Content-Type": "application/json",
        "Accept": "application/json"
    ]
    
    // Timeout intervals
    static let requestTimeout: TimeInterval = 30
    static let resourceTimeout: TimeInterval = 60
}

// Example usage in your API Service
class MotorMatesAPIService {
    
    static let shared = MotorMatesAPIService()
    
    private init() {}
    
    func testConnection(completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)\(Constants.API.testConnection)") else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        Constants.headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let message = json["message"] as? String else {
                completion(false, "Invalid response")
                return
            }
            
            completion(true, message)
        }.resume()
    }
    
    func checkForUpdates(completion: @escaping ([String: Any]?) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)\(Constants.API.appUpdates)") else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(nil)
                return
            }
            
            completion(json)
        }.resume()
    }
}