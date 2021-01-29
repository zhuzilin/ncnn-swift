//
//  ToArray.swift
//  SwiftNCNN
//
//  Created by Zilin Zhu on 2021/1/28.
//

import UIKit

extension UIImage {
    func toRgbaUInt8Array() -> [UInt8] {
        let w: Int = Int(self.size.width)
        let h: Int = Int(self.size.height)
        var rgba: [UInt8] = [UInt8](repeating: 0, count: w * h * 4)
        rgba.withUnsafeMutableBytes({ data in
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let context: CGContext = CGContext(data: data.baseAddress!,
                                            width: w, height: h,
                                            bitsPerComponent: 8, bytesPerRow: w * 4,
                                            space: colorSpace,
                                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))
        })
        return rgba
    }
}
