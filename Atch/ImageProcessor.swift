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
        
        let borderSize = CGSizeMake(image.size.width+12, image.size.height+12)
        UIGraphicsBeginImageContextWithOptions(borderSize, false,0.0)
        let imageBounds = CGRect(origin: CGPoint(x: 12, y: 12), size: image.size)
        UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: 0, y: 0), size: borderSize), cornerRadius: 100).addClip()
        let path = UIBezierPath(roundedRect: CGRectMake(6, 6, borderSize.width - 12, borderSize.height - 12), cornerRadius: 100)
        borderColour.setStroke()
        image.drawInRect(imageBounds)
        
        path.lineWidth = 12
        path.stroke()
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if markerSize {
            let size = CGSizeMake(60, 60)
            return resizeImage(finalImage, size: size)
        }
        return finalImage
    }
    
    static func resizeImage(image: UIImage, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.drawInRect(CGRectMake(0, 0, size.width, size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage
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
        UIGraphicsBeginImageContext(newSize)
        
        // Use existing opacity as is
        image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        maskImage.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height), blendMode: kCGBlendModeNormal, alpha: 1)
        //[image drawInRect:CGRectMake(0,0,newSize.width,newSize.height) blendMode:kCGBlendModeNormal alpha:1];
        
        // Apply supplied opacity if applicable
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
        
    }
    
    static func getColourMessageBubble(colour: UIColor) -> UIImage {
        let colourImage = ImageProcessor.makeImageColour("left_chat_bubble.png", colour: colour)
        let otherImage = UIImage(named: "right_chat_bubble.png")
        return ImageProcessor.maskImage(colourImage!, withMask: otherImage!)
    }
    
    static func createBackground(users: [String], externalRadius: CGFloat, internalRadius: CGFloat, bubbleRadius: CGFloat) -> UIImage {
        //return an image
        let centre = CGPoint(x: externalRadius, y: externalRadius)
        var clearRadius = CGFloat(0)
        if users.count > 2 {
            clearRadius = CGFloat(sqrt((internalRadius * internalRadius) - (bubbleRadius * bubbleRadius)))
        }
        
        println("clear radius: \(clearRadius)")

        let k = CGFloat(users.count)
        for var i = 0; i < users.count; i++ {
            var startAngle: CGFloat = ((2 * CGFloat(M_PI) * CGFloat(i)) / k) - CGFloat(M_PI)/2
            var endAngle: CGFloat = ((2 * CGFloat(M_PI) * CGFloat(i + 1)) / k) - CGFloat(M_PI)/2
            if users.count == 2 {
                startAngle += CGFloat(M_PI)/8
                endAngle += CGFloat(M_PI)/8
            }
            let centrexfromOrigin: CGFloat = externalRadius * sin(startAngle + CGFloat(M_PI)/2)
            let centreyfromOrigin: CGFloat = externalRadius * cos(startAngle + CGFloat(M_PI)/2)
            println("centrex: \(centrexfromOrigin) centrey: \(centreyfromOrigin)")
            let realx: CGFloat = externalRadius + centrexfromOrigin
            let realy: CGFloat = externalRadius - centreyfromOrigin
            let startPoint = CGPointMake(realx, realy)
            println("start angle: \(startAngle)")
            println("end angle: \(endAngle)")
            _friendManager.userMap[users[i]]!.colour!.setFill()
            let path = UIBezierPath()
            path.moveToPoint(startPoint)
            println("start point: \(startPoint)")
            path.lineWidth = 0
            path.addArcWithCenter(centre,
                radius: externalRadius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true)
            if users.count != 2 {
                path.addArcWithCenter(centre,
                    radius: clearRadius,
                    startAngle: endAngle,
                    endAngle: startAngle,
                    clockwise: false)
            }
            
            //path.addLineToPoint(centre)
            //path.stroke()
            path.fill()
            path.closePath()
        }
        //make clear circle in cent
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    static func createImageFromGroup(group: Group) -> UIImage? {
        let users = group.toUsers
        var userImages = [UIImage]()
        for user in users {
            if let image = _friendManager.userMap[user]?.image {
                userImages.append(ImageProcessor.createCircle(image, borderColour: _friendManager.userMap[user]!.colour!, markerSize: true))
            }
            else {
                if _friendManager.downloadedPics {
                    FacebookManager.downloadProfilePictures([_friendManager.userMap[user]!.parseObject!])
                }
            }
        }
        if userImages.count == 0 {
            
            return nil
        }
        if userImages.count == 1 {
            return userImages[0]
        }
        let testImage = userImages[0]
        //userImages.append(testImage)
        println("userImages.count: \(userImages.count)")
        let k = CGFloat(userImages.count)
        let d = CGFloat(60)
        let pi = CGFloat(M_PI)
        var internalRadius: CGFloat = (sin(pi * (0.5 - (1/k)))) / (sin(2*pi/k)) * d
        var externalRadius = internalRadius + (d/2)
        if userImages.count == 2 {
            internalRadius = d/2
            externalRadius = d
        }
        println("external radius \(externalRadius)")
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(externalRadius * 2, externalRadius * 2), false, 0.0)
        let test = createBackground(users, externalRadius: externalRadius, internalRadius: internalRadius, bubbleRadius: d/2)
        for var i = 0; i < Int(k); i++ {
            
            var theta = (2 * CGFloat(M_PI) * CGFloat(i)) / k
            if users.count == 2 {
                theta += CGFloat(M_PI)/8
            }
            println("theta: \(theta)")
            let centrexfromOrigin = internalRadius * CGFloat(sin(theta))
            let centreyfromOrigin = internalRadius * CGFloat(cos(theta))
            println("centrex: \(centrexfromOrigin) centrey: \(centreyfromOrigin)")
            let realx: CGFloat = externalRadius + centrexfromOrigin
            let realy: CGFloat = externalRadius - centreyfromOrigin
            println("realx: \(realx) realy \(realy)")
            let outsideCircleRect = CGRectMake(realx - d/2, realy - d/2, d, d)
            userImages[i].drawInRect(outsideCircleRect)
        }
        //UIBezierPath(roundedRect: CGRectMake(0, 0, externalRadius * 2, externalRadius * 2), cornerRadius: 100).addClip()
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        if userImages.count > 2 {
            return resizeImage(finalImage, size: CGSizeMake(100, 100))
        }
        else if userImages.count == 2 {
            return resizeImage(finalImage, size: CGSizeMake(100, 100))
        }
        return finalImage
    }
    
}