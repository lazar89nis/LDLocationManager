//
//  LDLocationManager.swift
//
//  Created by Lazar on 10/6/17.
//  Copyright © 2017 Lazar. All rights reserved.
//

import Foundation
import CoreLocation
import LDMainFramework

/// Struct with static variables used as names for NotificationCenter for specific events
public struct LDLocationManagerNotification
{
    // MARK: Notification names
    
    /// Notification name for notification when location is updated
    public static let locationUpdated = "LDLocationUpdated"
    
    /// Notification name for notification whem authorization status is changed
    public static let authorizationStatusChanged = "LDAuthorizationStatusChanged"
}

/// LDLocationManager class used for handle some operations with user's location
open class LDLocationManager: NSObject, CLLocationManagerDelegate
{
    // MARK: Basic properties
    
    /// CLLocationManager instance
    private var locationManager: CLLocationManager = CLLocationManager()
    
    /// Boolean value which indicates if tracking location is enabled
    private var isTrackingLocation: Bool = false
    
    // MARK: - Shared instance
    
    /// Shared (singleton instance)
    open static let sharedManager: LDLocationManager = {
        
        let instance = LDLocationManager()
        instance.locationManager.delegate = instance
        
        return instance
    }()
    
    // MARK: - Authorization
    
    /// Request Always Authorization
    open func requestAlwaysAuthorization()
    {
        locationManager.requestAlwaysAuthorization()
    }
    
    /// Request When In Use Authorization
    open func requestWhenInUseAuthorization()
    {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Returns whether the application is authorized for the location or not
    ///
    /// - Returns: Whether the application is authorized for the location or not
    open func isAppAutorized() -> Bool
    {
        let status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.authorizedAlways || status == CLAuthorizationStatus.authorizedWhenInUse {
            return true
        }
        else {
            return false
        }
    }
    
    /// Returns whether the application is always authorized for the location or not
    ///
    /// - Returns: Whether the application is always authorized for the location or not
    open func isAppAlwaysAutorized() -> Bool
    {
        let status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.authorizedAlways {
            return true
        }
        else {
            return false
        }
    }
    
    /// Returns whether the application is when in use authorized for the location or not
    ///
    /// - Returns: Whether the application is when in use authorized for the location or not
    open func isAppWhenInUseAutorized() -> Bool
    {
        let status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            return true
        }
        else {
            return false
        }
    }
    
    // MARK: - Location and Distance
    
    /// Configure locationManager object, start updating location, and request for permissions if needed.
    open func startTrackingLocation()
    {
        if !isTrackingLocation {
            
            locationManager.requestLocation()
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
            
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            
            locationManager.startUpdatingLocation()
            isTrackingLocation = true
        }
    }
    
    /// Stop updating location
    open func stopTrackingLocation()
    {
        if isTrackingLocation {
            
            locationManager.stopUpdatingLocation()
            isTrackingLocation = false
        }
    }
    
    /// Return user Current Location
    ///
    /// - Returns: Current location
    open func getCurrentLocation() -> CLLocation?
    {
        if let currentLocation = locationManager.location
        {
            return currentLocation
        }
        else
        {
            return nil
        }
    }
    
    /// Calculate distance for current to specified location.
    ///
    /// - Parameters:
    ///   - location: Target location
    ///   - inMiles: Whether the distance returns in miles. Default value is false.
    /// - Returns: Distance form current to target location
    open func getDistanceFromCurrentLocation(toLocation location: CLLocation?, inMiles:  Bool = false) -> Double?
    {
        if let toLocation = location {
            if let currentLocation = locationManager.location {
                let distance = currentLocation.distance(from: toLocation)
                if inMiles
                {
                    return distance
                }
                else
                {
                    return distance*0.621371
                }
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    /// Calculate distance for fromLocation to specified toLocation.
    ///
    /// - Parameters:
    ///   - from: Start Locatiom
    ///   - to: Target location
    ///   - inMiles: Whether the distance returns in miles. Default value is false.
    /// - Returns: Distance form start to target location
    open func getDistance(fromLocation from: CLLocation?, toLocation to: CLLocation?, inMiles:  Bool = false) -> Double?
    {
        if let toLocation = to {
            if let fromLocation = from {
                let distance = toLocation.distance(from: fromLocation)
                if inMiles
                {
                    return distance
                }
                else
                {
                    return distance*0.621371
                }
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    
    /// Get detailed information about user's location (country, city, street,...)
    ///
    /// - Parameter completion: Completion handler which will be executed when and if detailed informations about user's location are fetched
    open func getAdress(completion: @escaping ([CLPlacemark]) -> ()) {
        
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined, .restricted, .denied:
                print("No access")
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access")
                locationManager.requestWhenInUseAuthorization()
                if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
                    CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
                    if let currentLocation = locationManager.location
                    {
                        self.getAddress(location: currentLocation, completion: completion)
                    }
                }
            }
        } else {
            print("Location services are not enabled")
        }
    }
    
    
    /// Get detailed informations (country, city, address,..) about given location
    ///
    /// - Parameters:
    ///   - location: Location for which we need detailed informations
    ///   - completion: Completion handler which will be executed when and if detailed informations about given location are fetched
    open func getAddress(location:CLLocation, completion: @escaping ([CLPlacemark]) -> ())
    {
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) -> Void in
            
            if error != nil {
                print("Error getting location: \(error?.localizedDescription ?? "No description")")
                completion([])
            }
            else
            {
                if let placemarks = placemarks
                {
                    completion(placemarks)
                }
            }
        }
    }
    
    // MARK: - Location Manager Delegate
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let myCurrentLocation: CLLocation = locations.first!
        
        // Inform all about location update event. Observe this event to collect most recently retrieved user location.
        LDAppNotify.postNotification(LDLocationManagerNotification.locationUpdated, object: myCurrentLocation)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("LDLocationManager ERROR : \(error.localizedDescription)")
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        // Inform all about Authorization Status Change event. Observe this event to register Authorization Status Change event.
        LDAppNotify.postNotification(LDLocationManagerNotification.authorizationStatusChanged, object: status as AnyObject)
    }
}
