//
//  CrumbPathRenderer.swift
//  CrumbPath
//
//  Copyright (C) 2014 Apple Inc. All Rights Reserved.
//  See LICENSE.txt for this sample’s licensing information
//
//  Created by Backlin,Gene on 2/21/18.
//  Copyright © 2018 Backlin,Gene. All rights reserved.
//

import MapKit

let MIN_POINT_DELTA: CGFloat = 5.0

public class CrumbPathRenderer: MKOverlayRenderer {
    
    override public func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let crumPath: CrumbPath = overlay as! CrumbPath
        let lineWidth: CGFloat = MKRoadWidthAtZoomScale(zoomScale)
        
        // outset the map rect by the line width so that points just outside
        // of the currently drawn rect are included in the generated path.
        
        let clipRect: MKMapRect = MKMapRectInset(mapRect, Double(-lineWidth), Double(-lineWidth))
        var path: CGPath? = nil
        
        crumPath.readPointsWithBlockAndWait { [weak self] (points, pointsCount) in
            path = self!.newPath(points: points, pointCount: pointsCount, clipRect: clipRect, zoomScale: zoomScale)
        }
        
        if path != nil {
            context.addPath(path!)
            context.setStrokeColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.5)
            context.setLineJoin(.round)
            context.setLineCap(.round)
            context.setLineWidth(lineWidth)
            context.strokePath()
        }
    }
    
    func lineBetweenPointsIntersectsRect(point0: MKMapPoint, point1: MKMapPoint, rect1: MKMapRect) -> Bool {
        let minX: Double = min(point0.x, point0.x)
        let minY: Double = min(point0.y, point0.y)
        let maxX: Double = max(point0.x, point0.x)
        let maxY: Double = max(point0.y, point0.y)
        
        let rect2: MKMapRect = MKMapRectMake(minX, minY, maxX-minX, maxY-minY)
        
        return MKMapRectIntersectsRect(rect1, rect2)
    }
    
    func newPath(points: [MKMapPoint], pointCount: Int, clipRect: MKMapRect, zoomScale: MKZoomScale) -> CGPath? {
        var path: CGMutablePath?
        
        // The fastest way to draw a path in an MKOverlayView is to simplify the
        // geometry for the screen by eliding points that are too close together
        // and to omit any line segments that do not intersect the clipping rect.
        // While it is possible to just add all the points and let CoreGraphics
        // handle clipping and flatness, it is much faster to do it yourself:
        //
        if pointCount > 1 {
            path = CGMutablePath()
            var needsMove = true
            
            // Calculate the minimum distance between any two points by figuring out
            // how many map points correspond to MIN_POINT_DELTA of screen points
            // at the current zoomScale.
            let minPointDelta: Double = Double(MIN_POINT_DELTA/zoomScale)
            let squareMinPointDelta = power(minPointDelta)
            
            var lastPoint: MKMapPoint = points[0]
            for index in 1...pointCount-1 {
                let mapPoint: MKMapPoint = points[index]
                let delta = power(mapPoint.x - lastPoint.x) + power(mapPoint.y - lastPoint.y)
                
                if delta >= Double(squareMinPointDelta) {
                    if lineBetweenPointsIntersectsRect(point0: mapPoint, point1: lastPoint, rect1: clipRect) == true {
                        if needsMove == true {
                            let lastCGPoint: CGPoint = point(for: lastPoint)
                            path!.move(to: CGPoint(x: lastCGPoint.x, y: lastCGPoint.y))
                        }
                        let cgPoint: CGPoint = point(for: mapPoint)
                        path!.addLine(to: CGPoint(x: cgPoint.x, y: cgPoint.y))
                        needsMove = false
                    } else {
                        // discontinuity, lift the pen
                        needsMove = true
                    }
                }
                lastPoint = mapPoint
            }
            
            // If the last line segment intersects the mapRect at all, add it unconditionally
            let mapPoint: MKMapPoint = points[pointCount-1]
            if lineBetweenPointsIntersectsRect(point0: mapPoint, point1: lastPoint, rect1: clipRect) == true {
                if needsMove == true {
                    let lastCGPoint: CGPoint = point(for: lastPoint)
                    path!.move(to: CGPoint(x: lastCGPoint.x, y: lastCGPoint.y))
                }
                let cgPoint: CGPoint = point(for: mapPoint)
                path!.addLine(to: CGPoint(x: cgPoint.x, y: cgPoint.y))
            }
        }
        
        return path
    }
    
    func power(_ number: Double) -> Double {
        return number * number
    }
    
    
}

