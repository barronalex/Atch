//
//  ColourGenerator.swift
//  Atch
//
//  Created by Alex Barron on 8/28/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation

class ColourGenerator {
    static func generateRandomColour() -> UIColor {
        while(true) {
            let r = Int(arc4random_uniform(255))
            let b: Int = Int(arc4random_uniform(255))
            let g: Int = Int(arc4random_uniform(255))
            if (abs((r - g)) < 20 && b < 50) { continue }
            if (abs(r - g) < 20 && abs(r - b) < 20) { continue }
            if (r + g + b < 100) { continue }
            if (r + g + b > 550) { continue }
            if (r + g > 430 && b < 120) { continue }
            println("redvalue: \(CGFloat(r))")
            println("blueValue: \(CGFloat(b))")
            println("greenValue: \(CGFloat(g))")
            let colour = UIColor(red: CGFloat(r)/255, green: CGFloat(b)/255, blue: CGFloat(g)/255, alpha: 255)
            return colour

        }
    }
    
    static func getAssociatedColour(colour: UIColor) -> UIColor {
        var h = CGFloat()
        var s = CGFloat()
        var b = CGFloat()
        var a = CGFloat()
        if colour.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return UIColor(hue: h, saturation: 2*s, brightness: b, alpha: a)
        }
        return colour
    }
}