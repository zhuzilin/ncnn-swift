//
//  Resize.swift
//  SwiftNCNN
//
//  Created by Zilin Zhu on 2021/1/28.
//

import UIKit

// From https://stackoverflow.com/a/31314494/5163915
extension UIImage {
    func resize(targetSize: CGSize) -> UIImage {
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
}
