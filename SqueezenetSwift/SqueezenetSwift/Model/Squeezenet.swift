//
//  SqueezeNet.swift
//  SwiftNCNN
//
//  Created by Zilin Zhu on 2021/1/29.
//

import SwiftUI

class Squeezenet {
    var label: [Int: String] = [:]
    let net: Net
    
    init?() {
        // MARK: initialize net
        net = Net()
        let paramBinPath = Bundle.main.path(forResource: "squeezenet_v1.1.param", ofType: "bin")
        guard net.loadParamBin(paramBinPath) == 0 else {
            return nil
        }
        let modelPath = Bundle.main.path(forResource: "squeezenet_v1.1", ofType: "bin")
        guard net.loadModel(modelPath) == 0 else {
            return nil
        }
        
        // MARK: load label
        do {
            let labelPath = Bundle.main.path(forResource: "label", ofType: "json")!
            let data = try Data(contentsOf: URL(fileURLWithPath: labelPath), options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: [])
            let labelDict = jsonResult as! [String: String]
            for (key, val) in labelDict {
                label[Int(key)!] = val
            }
        } catch {
            return nil
        }
    }
    
    func predict(for image: UIImage, top: Int = 1) -> [(Int, Float)] {
        let resizedImage = image.resize(targetSize: CGSize(width: 227, height: 227))
        let rgba = resizedImage.toRgbaUInt8Array()

        let inputData: Data = Data(copyingBufferOf: rgba)
        // 65540 is ncnn::Mat::PIXEL_RGBA2RGB
        let input: Mat = Mat.init(fromPixels: inputData, 65540, 227, 227)
        // TODO: Find a better way to pass [Float] to objective-C.
        let mean: [NSNumber] = [NSNumber(value: 104.0), NSNumber(value: 117.0), NSNumber(value: 123.0)]
        input.substractMeanNormalize(mean, nil)

        // BLOB_data is 0, BLOB_prob is 82
        let output: [NSNumber: Mat] = net.run([0: input], [82])
        let outputData: Data = output[82]!.toData()!
        let outputProb: [Float] = outputData.toArray(type: Float.self)

        let sortedOutput = outputProb.enumerated()
                                    .map { ($0, $1) }
                                    .sorted { $0.1 > $1.1 }
        return Array(sortedOutput[..<top])
    }
}
