//
//  ImageProcessor.swift
//  Atch
//
//  Created by Alex Barron on 8/19/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit
import CoreGraphics

class ImageProcessor {
    
    static func createCircle(image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false,0.0)
        let bounds = CGRect(origin: CGPointZero, size: image.size)
        UIBezierPath(roundedRect: bounds, cornerRadius: 50).addClip()
        image.drawInRect(bounds)
        let finalImage=UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return finalImage
    }
    
}