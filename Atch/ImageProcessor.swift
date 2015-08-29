//
//  ImageProcessor.swift
//  Atch
//
//  Created by Alex Barron on 8/19/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit
import CoreGraphics
import Foundation

class ImageProcessor {
    
    static func createCircle(image: UIImage, borderColour: UIColor, markerSize: Bool) -> UIImage {
        
        let borderSize = CGSizeMake(image.size.width+10, image.size.height+10)
        UIGraphicsBeginImageContextWithOptions(borderSize, false,0.0)
        let imageBounds = CGRect(origin: CGPoint(x: sqrt(CGFloat(50)), y: sqrt(CGFloat(50))), size: image.size)
        let path = UIBezierPath(roundedRect: imageBounds, cornerRadius: 50)
        borderColour.setStroke()
        path.lineWidth = 5
        path.stroke()
        UIBezierPath(roundedRect: imageBounds, cornerRadius: 50).addClip()
        image.drawInRect(imageBounds)
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if markerSize {
            let size = CGSizeMake(60, 60)
            UIGraphicsBeginImageContext(size)
            finalImage.drawInRect(CGRectMake(0, 0, size.width, size.height))
            let newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return newImage
        }
        return finalImage
    }
    
    static func makeImageColour(imageName: String, colour: UIColor) -> UIImage? {
        let image = UIImage(named: imageName)
        if image == nil { return nil }
        UIGraphicsBeginImageContextWithOptions(image!.size, false, image!.scale)
        colour.setFill()
        
        let context = UIGraphicsGetCurrentContext() as CGContextRef
        CGContextTranslateCTM(context, 0, image!.size.height)
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextSetBlendMode(context, kCGBlendModeNormal)
        
        let rect = CGRectMake(0, 0, image!.size.width, image!.size.height) as CGRect
        CGContextClipToMask(context, rect, image!.CGImage)
        CGContextFillRect(context, rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext() as UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    static func maskImage(image: UIImage, withMask maskImage: UIImage) -> UIImage {
        
        let newSize = image.size
        println("size: \(newSize)")
        UIGraphicsBeginImageContext(newSize);
        
        // Use existing opacity as is
        image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        maskImage.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height), blendMode: kCGBlendModeNormal, alpha: 1)
        //[image drawInRect:CGRectMake(0,0,newSize.width,newSize.height) blendMode:kCGBlendModeNormal alpha:1];
        
        // Apply supplied opacity if applicable
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return newImage
        
    }
    
    static func getColourMessageBubble(colour: UIColor) -> UIImage {
        let colourImage = ImageProcessor.makeImageColour("left_chat_bubble.png", colour: colour)
        let otherImage = UIImage(named: "right_chat_bubble.png")
        return ImageProcessor.maskImage(colourImage!, withMask: otherImage!)
    }
    
    static func createImageFromGroup(group: Group) -> UIImage? {
        
        if let image = _friendManager.friendPics[group.toUsers[0]] {
            return ImageProcessor.createCircle(image, borderColour: _friendManager.userMap[group.toUsers[0]]!.colour!, markerSize: true)
        }
        return nil
        
//        println("here")
//        println("friendPics: \(_friendManager.friendPics)")
//        let users = group.toUsers
//        var userImages = [UIImage]()
//        for user in users {
//            if let image = _friendManager.friendPics[user] {
//                
//                userImages.append(ImageProcessor.createCircle(image, borderColour: UIColor.blueColor(), markerSize: true))
//            }
//        }
//        if userImages.count == 0 {
//            
//            return nil
//        }
//        let testImage = userImages[0]
//        userImages.append(testImage)
//        println("userImages.count: \(userImages.count)")
//        let k = CGFloat(userImages.count)
//        let d = CGFloat(60)
//        
//        let internalRadius: CGFloat = (sin(180 * (0.5 - (1/k)))) / (sin(360/k)) * d
//        let externalRadius = internalRadius + (d/2)
//        println("external radius \(externalRadius)")
//        UIGraphicsBeginImageContextWithOptions(CGSizeMake(externalRadius * 2, externalRadius * 2), false, 0.0)
//        //at end we'll clip to external circle bounds
//        //put first circle at top of rectangle
//        //draw circle in rect
//        //get points on circle
//        for var i = 0; i < Int(k); i++ {
//            let theta = (360 * CGFloat(i)) / k
//            println("theta: \(theta)")
//            let centrexfromOrigin = internalRadius * sin(theta)
//            let centreyfromOrigin = internalRadius * cos(theta)
//            println("centrex: \(centrexfromOrigin) centrey: \(centreyfromOrigin)")
//            let realx = externalRadius + centrexfromOrigin
//            let realy = externalRadius - centreyfromOrigin
//            println("realx: \(realx) realy \(realy)")
//            //draw a circle with centre at realx, realy
//            let outsideCircleRect = CGRectMake(realx - d/2, realy - d/2, d, d)
//            userImages[i].drawInRect(outsideCircleRect)
//        }
//        //UIBezierPath(roundedRect: CGRectMake(0, 0, externalRadius * 2, externalRadius * 2), cornerRadius: 50).addClip()
//        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return finalImage
    }
    
}