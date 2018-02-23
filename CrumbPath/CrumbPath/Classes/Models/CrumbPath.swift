//
//  CrumbPath.swift
//  CrumbPath
//
//  Copyright (C) 2014 Apple Inc. All Rights Reserved.
//  See LICENSE.txt for this sample’s licensing information
//
//  Created by Backlin,Gene on 2/21/18.
//  Copyright © 2018 Backlin,Gene. All rights reserved.
//

import MapKit

let MINIMUM_DELTA_METERS = 10.0

public class CrumbPath: NSObject, MKOverlay {
    
    @objc public var coordinate: CLLocationCoordinate2D {
        get {
            var centerCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
            readPointsWithBlockAndWait { (pointsArray, pointsCount) in
                centerCoordinate = MKCoordinateForMapPoint(pointsArray[0])
            }
            return centerCoordinate
        }
    }

    // Updated by -addCoordinate:boundingMapRectChanged: if needed to contain the new coordinate.
    @objc public var boundingMapRect: MKMapRect = MKMapRect()
    
    var pointBuffer: [MKMapPoint] = [MKMapPoint]()
    var pointCount: Int?
    var pointBufferCapacity: Int?

    var rwLock: RWLock!
    
    // MARK: - Initialization
    
    public init(coordinate: CLLocationCoordinate2D) {
        super.init()
        
        // Initialize point storage and place this first coordinate in it
        pointBufferCapacity = 1000
        pointBuffer.reserveCapacity(pointBufferCapacity!)
        
        let origin: MKMapPoint = MKMapPointForCoordinate(coordinate)
        pointBuffer.append(origin)
        pointCount = 1
        
        // Default -boundingMapRect size is 1km^2 centered on coord
        let oneKilometerInMapPoints = Double(pointBufferCapacity!) * MKMapPointsPerMeterAtLatitude(coordinate.latitude)
        let oneSquareKilometer: MKMapSize = MKMapSize(width: oneKilometerInMapPoints, height: oneKilometerInMapPoints)
        
        boundingMapRect = MKMapRect(origin: origin, size: oneSquareKilometer)
        
        // Clamp the rect to be within the world
        boundingMapRect = MKMapRectIntersection(boundingMapRect, MKMapRectWorld);
        
        // Initialize read-write lock for drawing and updates
        //
        // We didn't use this lock during this method because
        // it's our user's responsibility not to use us before
        // -init completes.
        
        rwLock = RWLock()
    }
    
    deinit {
        rwLock.unlock()
    }
    
    // MARK: - Utility methods
    
    func readPointsWithBlockAndWait(completion: @escaping (_ pointsArray: [MKMapPoint], _ pointsCount: Int)-> Void) {
        rwLock.doWithWriteLock { () -> Void in
            completion(pointBuffer, pointCount!)
        }
    }
    
    func grow(overlayBounds: MKMapRect, toInclude otherRect: MKMapRect) -> MKMapRect {
        // The -boundingMapRect we choose was too small.
        // We grow it to be both rects, plus about
        // an extra kilometer in every direction that was too small before.
        // Usually the crumb-trail will keep growing in the direction it grew before
        // so this minimizes having to regrow, without growing off-trail.
        
        var grownBounds: MKMapRect = MKMapRectUnion(overlayBounds, otherRect)
        
        // Pedantically, to grow the overlay by one real kilometer, we would need to
        // grow different sides by a different number of map points, to account for
        // the number of map points per meter changing with latitude.
        // But we don't need to be exact. The center of the rect that ran over
        // is a good enough estimate for where we'll be growing the overlay.
        
        let oneKilometerInMapPoints: Double = 1000.00 * MKMapPointsPerMeterAtLatitude(MKCoordinateForMapPoint(otherRect.origin).latitude)

        // Grow by an extra kilometer in the direction of each overrun.

        if MKMapRectGetMinY(otherRect) < MKMapRectGetMinY(overlayBounds) {
            grownBounds.origin.y -= oneKilometerInMapPoints
            grownBounds.size.height += oneKilometerInMapPoints
        } else if MKMapRectGetMaxY(otherRect) > MKMapRectGetMaxY(overlayBounds) {
            grownBounds.size.height += oneKilometerInMapPoints
        }
        
        if MKMapRectGetMinX(otherRect) < MKMapRectGetMinX(overlayBounds) {
            grownBounds.origin.x -= oneKilometerInMapPoints
            grownBounds.size.width += oneKilometerInMapPoints
        } else if MKMapRectGetMaxX(otherRect) > MKMapRectGetMaxX(overlayBounds) {
            grownBounds.size.width += oneKilometerInMapPoints
        }
        
        // Clip to world size
        grownBounds = MKMapRectIntersection(grownBounds, MKMapRectWorld)

        return grownBounds
    }
    
    func mapRectContaining(point1: MKMapPoint, point2: MKMapPoint) -> MKMapRect {
        let pointSize: MKMapSize = MKMapSize(width: 0.0, height: 0.0)
        
        let newPointRect: MKMapRect = MKMapRect(origin: point1, size: pointSize)
        let prevPointRect: MKMapRect = MKMapRect(origin: point2, size: pointSize)
        
        return MKMapRectUnion(newPointRect, prevPointRect)
    }

    public func add(_ coordinate: CLLocationCoordinate2D, _ boundingMapRectChangedOut: inout Bool) -> MKMapRect {
        // Assume no changes until we make one.
        var isBoundingMapRectChanged = false
        var updateRect: MKMapRect = MKMapRectNull
        
        // Acquire the write lock because we are going to be changing the list of points
        rwLock.doWithWriteLock { () -> Void in
            // Convert to map space
            let newPoint: MKMapPoint = MKMapPointForCoordinate(coordinate)
            
            // Get the distance between this new point and the previous point.
            let prevPoint: MKMapPoint = pointBuffer[pointCount! - 1]
            let metersApart: CLLocationDistance = MKMetersBetweenMapPoints(newPoint, prevPoint)
            
            // Ignore the point if it's too close to the previous one.
            if metersApart > MINIMUM_DELTA_METERS {
                // Grow the points buffer if necessary
                if pointBufferCapacity == pointCount {
                    pointBufferCapacity! *= 2;
                    pointBuffer.reserveCapacity(pointBufferCapacity!)
                }
                
                // Add the new point to the points buffer
                pointBuffer.append(newPoint)
                pointCount! += 1
                
                // Compute MKMapRect bounding prevPoint and newPoint
                updateRect = mapRectContaining(point1: newPoint, point2: prevPoint)
                
                // Update the -boundingMapRect to hold the new point if needed
                let overlayBounds: MKMapRect = boundingMapRect
                if MKMapRectContainsRect(overlayBounds,updateRect) == false {
                    boundingMapRect = grow(overlayBounds: overlayBounds, toInclude: updateRect)
                    isBoundingMapRectChanged = true
                }
            }
            
            // Report if -boundingMapRect changed
            if boundingMapRectChangedOut == false {
                boundingMapRectChangedOut = isBoundingMapRectChanged
            }
        }
        
        return updateRect
    }
}

