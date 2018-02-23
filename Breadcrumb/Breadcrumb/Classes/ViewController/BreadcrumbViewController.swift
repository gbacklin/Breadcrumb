//
//  BreadcrumbViewController.swift
//  Breadcrumb
//
//  Copyright (C) 2014 Apple Inc. All Rights Reserved.
//  See LICENSE.txt for this sample’s licensing information
//
//  Created by Backlin,Gene on 2/21/18.
//  Copyright © 2018 Backlin,Gene. All rights reserved.
//

import UIKit
import MapKit
import AVFoundation        // for AVAudioSession
import CrumbPath

let kDebugShowArea = true

class BreadcrumbViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    var audioPlayer: AVAudioPlayer?
    var crumbs: CrumbPath?
    var crumbPathRenderer: CrumbPathRenderer?
    var drawingAreaRenderer: MKPolygonRenderer?   // shown if kDebugShowArea is set to 1
    var locationManager: CLLocationManager?
    var titleText = "Breadcrumb"
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initilizeAudioPlayer()
        initilizeLocationTracking()
        
        NotificationCenter.default.addObserver(self, selector: #selector(BreadcrumbViewController.settingsDidChange(_:)), name: UserDefaults.didChangeNotification, object: nil)
        
        // allow the user to change the tracking mode on the map view by placing this button in the navigation bar
        let userTrackingButton: MKUserTrackingBarButtonItem = MKUserTrackingBarButtonItem(mapView: mapView)
        //userTrackingButton.tintColor = UIColor.white
        navigationItem.leftBarButtonItem = userTrackingButton
        
        self.navigationController!.navigationBar.tintColor = UIColor.white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = titleText
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        titleText = title!
        title = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        // even though we are using ARC we still need to:
        
        // 1) properly balance the unregister from the NSNotificationCenter,
        // which was registered previously in "viewDidLoad"
        //
        NotificationCenter.default.removeObserver(self)
        
        // 2) manually unregister for delegate callbacks,
        // As of iOS 7, most system objects still use __unsafe_unretained delegates for compatibility.
        //
        locationManager!.delegate = nil;
        audioPlayer!.delegate = nil;
    }
    
    // MARK: - Initialize Location Tracking
    
    func initilizeLocationTracking() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        // iOS 8 introduced a more powerful privacy model: <https://developer.apple.com/videos/wwdc/2014/?id=706>.
        // We use -respondsToSelector: to only call the new authorization API on systems that support it.
        //
        
        if locationManager!.responds(to: #selector(CLLocationManager.requestWhenInUseAuthorization)) {
            locationManager!.requestWhenInUseAuthorization()
            // note: doing so will provide the blue status bar indicating iOS
            // will be tracking your location, when this sample is backgrounded
        }
        
        // By default we use the best accuracy setting (kCLLocationAccuracyBest)
        //
        // You may instead want to use kCLLocationAccuracyBestForNavigation, which is the highest possible
        // accuracy and combine it with additional sensor data.  Note that level of accuracy is intended
        // for use in navigation applications that require precise position information at all times and
        // are intended to be used only while the device is plugged in.
        //
        locationManager!.desiredAccuracy = UserDefaults.standard.double(forKey: LocationTrackingAccuracyPrefsKey)
        
        // start tracking the user's location
        locationManager?.startUpdatingLocation()
        
        // Observe the application going in and out of the background, so we can toggle location tracking.
        NotificationCenter.default.addObserver(self, selector: #selector(BreadcrumbViewController.handleUIApplicationDidEnterBackgroundNotification(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BreadcrumbViewController.handleUIApplicationWillEnterForegroundNotification(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    // MARK: - Notifications selector methods
    
    @objc func settingsDidChange(_ notification: Notification) {
        let settings: UserDefaults = UserDefaults.standard
        
        // update our location manager for these settings changes:
        
        // accuracy (CLLocationAccuracy)
        let desiredAccuracy: CLLocationAccuracy = settings.double(forKey: LocationTrackingAccuracyPrefsKey)
        locationManager!.desiredAccuracy = desiredAccuracy
        
        // note:
        // for "PlaySoundOnLocationUpdatePrefsKey", code to play the sound later will read this default value
        // for "TrackLocationInBackgroundPrefsKey", code to track location in background will read this default value
    }
    
    @objc func handleUIApplicationDidEnterBackgroundNotification(_ notification: Notification) {
        switchToBackgroundMode(isInBackground: true)
    }
    
    @objc func handleUIApplicationWillEnterForegroundNotification(_ notification: Notification) {
        switchToBackgroundMode(isInBackground: false)
    }
    
    // MARK: - Utility methods
    
    // called when the app is moved to the background (user presses the home button) or to the foreground
    //
    func switchToBackgroundMode(isInBackground: Bool) {
        if UserDefaults.standard.bool(forKey: TrackLocationInBackgroundPrefsKey) == false {
            if isInBackground == true {
                locationManager!.stopUpdatingLocation()
            } else {
                locationManager!.startUpdatingLocation()
            }
        }
    }
}

// MARK: - Audio Support

extension BreadcrumbViewController {
    
    func initilizeAudioPlayer() {
        // set our default audio session state
        setSessionActiveWithMixing(isActive: false)
        
        do {
            let heroSoundURL: URL? = URL(fileURLWithPath: Bundle.main.path(forResource: "Hero", ofType: "aiff")!)
            if heroSoundURL != nil {
                audioPlayer = try AVAudioPlayer(contentsOf: heroSoundURL!)
            }
        } catch {
            print("initilizeAudioPlayer: \(error.localizedDescription)")
        }
        
    }
    
    func setSessionActiveWithMixing(isActive: Bool) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            
            if AVAudioSession.sharedInstance().isOtherAudioPlaying == true && isActive == true {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [.mixWithOthers, .duckOthers])
            }
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("setSessionActiveWithMixing: \(error.localizedDescription)")
        }
    }
    
    func playSound() {
        if audioPlayer != nil && audioPlayer!.isPlaying == false {
            audioPlayer!.prepareToPlay()
            audioPlayer!.play()
        }
    }
}

// MARK: - MKMapViewDelegate

extension BreadcrumbViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        var renderer: MKOverlayRenderer = MKOverlayRenderer()
        if overlay is CrumbPath {
            if crumbPathRenderer == nil {
                crumbPathRenderer = CrumbPathRenderer(overlay: overlay)
            }
            renderer = crumbPathRenderer!
        } else if overlay is [MKPolygon] {
            if kDebugShowArea == true {
                if drawingAreaRenderer!.polygon .isEqual(overlay) == false {
                    drawingAreaRenderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
                    drawingAreaRenderer!.fillColor = UIColor.blue.withAlphaComponent(0.25)
                }
                renderer = crumbPathRenderer!
            }
        }
        return renderer
    }
}

// MARK: - CLLocationManagerDelegate

extension BreadcrumbViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            if UserDefaults.standard.bool(forKey: PlaySoundOnLocationUpdatePrefsKey) == true {
                setSessionActiveWithMixing(isActive: true) // YES == duck if other audio is playing
                playSound()
            }
            // we are not using deferred location updates, so always use the latest location
            let newLocation: CLLocation = locations[0]
            
            if crumbs == nil {
                // This is the first time we're getting a location update, so create
                // the CrumbPath and add it to the map.
                //
                crumbs = CrumbPath(coordinate: newLocation.coordinate)
                mapView.add(crumbs!, level: .aboveRoads)
                
                // on the first location update only, zoom map to user location
                let newCoordinate: CLLocationCoordinate2D = newLocation.coordinate
                
                // default -boundingMapRect size is 1km^2 centered on coord
                let region: MKCoordinateRegion = coordinateRegion(withCenterCoordinate: newCoordinate, approximateRadiusInMeters: 2500)
                
                mapView.setRegion(region, animated: true)
            } else {
                // This is a subsequent location update.
                //
                // If the crumbs MKOverlay model object determines that the current location has moved
                // far enough from the previous location, use the returned updateRect to redraw just
                // the changed area.
                //
                // note: cell-based devices will locate you using the triangulation of the cell towers.
                // so you may experience spikes in location data (in small time intervals)
                // due to cell tower triangulation.
                //
                var boundingMapRectChanged = false
                var updateRect: MKMapRect = crumbs!.add(newLocation.coordinate, &boundingMapRectChanged)
                
                if boundingMapRectChanged == true {
                    // MKMapView expects an overlay's boundingMapRect to never change (it's a readonly @property).
                    // So for the MapView to recognize the overlay's size has changed, we remove it, then add it again.
                    mapView.removeOverlays(mapView.overlays)
                    crumbPathRenderer = nil
                    mapView.add(crumbs!, level: .aboveRoads)
                    let mapRect = crumbs!.boundingMapRect
                    var pts: [MKMapPoint] = [MKMapPoint]()
                    pts.append(MKMapPointMake(MKMapRectGetMinX(mapRect), MKMapRectGetMinY(mapRect)))
                    pts.append(MKMapPointMake(MKMapRectGetMinX(mapRect), MKMapRectGetMaxY(mapRect)))
                    pts.append(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMaxY(mapRect)))
                    pts.append(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMinY(mapRect)))
                    
                    let count = MemoryLayout.size(ofValue: pts) * MemoryLayout.size(ofValue: pts) / MemoryLayout.size(ofValue: pts[0]) * 2
                    let boundingMapRectOverlay = MKPolygon(points: pts, count: count)
                    
                    mapView.add(boundingMapRectOverlay, level: .aboveRoads)
                } else if MKMapRectIsNull(updateRect) == false {
                    // There is a non null update rect.
                    // Compute the currently visible map zoom scale
                    let currentZoomScale: MKZoomScale = CGFloat(mapView.bounds.size.width) / CGFloat(mapView.visibleMapRect.size.width)
                    // Find out the line width at this zoom scale and outset the updateRect by that amount
                    let lineWidth = MKRoadWidthAtZoomScale(currentZoomScale)
                    updateRect = MKMapRectInset(updateRect, Double(-lineWidth), Double(-lineWidth))
                    // Ask the overlay view to update just the changed area.
                    crumbPathRenderer?.setNeedsDisplayIn(updateRect)
                }
            }
        }
    }
    
    func coordinateRegion(withCenterCoordinate: CLLocationCoordinate2D, approximateRadiusInMeters: CLLocationDistance) -> MKCoordinateRegion {
        // Multiplying by MKMapPointsPerMeterAtLatitude at the center is only approximate, since latitude isn't fixed
        //
        let radiusInMapPoints = approximateRadiusInMeters * MKMapPointsPerMeterAtLatitude(withCenterCoordinate.latitude)
        let radiusSquared = MKMapSize(width: radiusInMapPoints, height: radiusInMapPoints)
        
        let regionOrigin = MKMapPointForCoordinate(withCenterCoordinate)
        var regionRect = MKMapRect(origin: regionOrigin, size: radiusSquared) //origin is the top-left corner
        
        // clamp the rect to be within the world
        regionRect = MKMapRectIntersection(regionRect, MKMapRectWorld)
        
        return MKCoordinateRegionForMapRect(regionRect)
    }
    
    func descriptionOfCLAuthorizationStatus(_ status: CLAuthorizationStatus) -> String {
        var statusReturnString = "Unknown CLAuthorizationStatus: \(status)"
        switch status {
        case .notDetermined:
            statusReturnString = "CLAuthorizationStatusNotDetermined"
        case .restricted:
            statusReturnString = "CLAuthorizationStatusRestricted"
        case .denied:
            statusReturnString = "CLAuthorizationStatusDenied"
        case .authorizedAlways:
            statusReturnString = "CLAuthorizationStatusAuthorizedAlways"
        case .authorizedWhenInUse:
            statusReturnString = "CLAuthorizationStatusAuthorizedWhenInUse"
        }
        return statusReturnString
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("\(#file):\(#line) \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("\(#file):\(#line) \(descriptionOfCLAuthorizationStatus(status))")
    }
}

// MARK: - AVAudioPlayerDelegate

extension BreadcrumbViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("\(#file):\(#line) \(error.localizedDescription)")
        }
    }
}

