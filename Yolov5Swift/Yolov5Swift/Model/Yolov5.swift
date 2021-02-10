//
//  Yolov5.swift
//  Yolov5Swift
//
//  Created by Zilin Zhu on 2021/1/30.
//

import SwiftUI

let maxLength: CGFloat = 640

struct Object {
    let x: Float
    let y: Float
    let w: Float
    let h: Float
    let label: Int
    let prob: Float
    
    var area: Float { w * h }
    
    static func interArea(_ a: Object, _ b: Object) -> Float {
        if a.x > b.x + b.w || a.x + a.w < b.x || a.y > b.y + b.h || a.y + a.h < b.y {
            return 0
        }

        let inter_width = min(a.x + a.w, b.x + b.w) - max(a.x, b.x)
        let inter_height = min(a.y + a.h, b.y + b.h) - max(a.y, b.y)
        return inter_width * inter_height
    }
}

class Yolov5 {
    let net: Net
    
    init?() {
        // MARK: initialize net
        net = Net()
        net.registerCustomLayer("YoloV5Focus")
        let paramPath = Bundle.main.path(forResource: "yolov5s", ofType: "param")
        guard net.loadParam(paramPath) == 0 else {
            return nil
        }
        let modelPath = Bundle.main.path(forResource: "yolov5s", ofType: "bin")
        guard net.loadModel(modelPath) == 0 else {
            return nil
        }
    }
    
    func predict(for image: UIImage) -> ([Object], Double) {
        
        // Yolo requires the width and height of the image are both multiplier of 32.
        var targetW = image.size.width
        var targetH = image.size.height
        if targetW < targetH {
            targetW = CGFloat(Int(targetW / targetH * maxLength) / 32 * 32)
            targetH = maxLength
        } else {
            targetH = CGFloat(Int(targetH / targetW * maxLength) / 32 * 32)
            targetW = maxLength
        }
        
        let start = Date()

        let path = Bundle.main.path(forResource: "dogs", ofType: "jpg")!
        let input: Mat = Mat.init(fromPathResize: path, Int32(targetW), Int32(targetH))
        
        let std: [NSNumber] = [NSNumber(value: 1 / 255.0), NSNumber(value: 1 / 255.0), NSNumber(value: 1 / 255.0)]
        input.substractMeanNormalize(nil, std)
        
        //print(start.timeIntervalSinceNow * -1000)
        
        let outputs = net.run(withName: ["images": input], ["output", "781", "801"])!
        
        //print(start.timeIntervalSinceNow * -1000)
        
        var proposals: [Object] = []
        proposals += generateProposals(stride: 8, input: input, feature: outputs["output"]!)
        proposals += generateProposals(stride: 16, input: input, feature: outputs["781"]!)
        proposals += generateProposals(stride: 32, input: input, feature: outputs["801"]!)
        
        //print(start.timeIntervalSinceNow * -1000)
        
        proposals.sort { $0.prob > $1.prob }
        let result = nmsSortedBboxes(from: proposals)
        
        //print(start.timeIntervalSinceNow * -1000)
        
        return (result, start.timeIntervalSinceNow * -1000)
    }
    
    func generateProposals(stride: Int, input: Mat, feature: Mat) -> [Object] {
        guard let anchors = anchorDict[stride] else {
            return []
        }
        let w = Int(feature.w())
        let h = Int(feature.h())
        let c = Int(feature.c())
        guard anchors.count % 2 == 0 else {
            return []
        }
        guard c == anchors.count / 2 else {
            return []
        }

        let numGrid = h
        let numGridX: Int
        let numGridY: Int
        if input.w() > input.h() {
            numGridX = Int(input.w()) / stride
            numGridY = numGrid / numGridX
        } else {
            numGridY = Int(input.h()) / stride
            numGridX = numGrid / numGridY
        }
        let numClass = w - 5
        let numAnchors = anchors.count / 2

        let featureArray: [Float] = feature.toData()!.toArray(type: Float.self)
        assert(featureArray.count == w * h * c)
        var objects: [Object] = []
        for q in 0..<numAnchors {
            let anchorW = anchors[q * 2]
            let anchorH = anchors[q * 2 + 1]

            let channelOffset = q * w * h
            for i in 0..<numGridY {
                for j in 0..<numGridX {
                    let rowOffset = w * (i*numGridX + j)
                    var classIndex: Int = -1
                    var classScore: Float = -1000
                    for k in 0..<numClass {
                        let score = featureArray[channelOffset + rowOffset + 5 + k]
                        if score > classScore {
                            classIndex = k
                            classScore = score
                        }
                    }
                    let boxScore = featureArray[channelOffset + rowOffset + 4]
                    let confidence = sigmoid(x: boxScore) * sigmoid(x: classScore)
                    if confidence >= probThreshold {
                        let dx = sigmoid(x: featureArray[channelOffset + rowOffset])
                        let dy = sigmoid(x: featureArray[channelOffset + rowOffset + 1])
                        let dw = sigmoid(x: featureArray[channelOffset + rowOffset + 2])
                        let dh = sigmoid(x: featureArray[channelOffset + rowOffset + 3])
                    
                        let pbCx = (dx * 2.0 - 0.5 + Float(j)) * Float(stride)
                        let pbCy = (dy * 2.0 - 0.5 + Float(i)) * Float(stride)
                        let pbW = pow(dw * 2.0, 2) * anchorW
                        let pbH = pow(dh * 2.0, 2) * anchorH
                        
                        let x0 = pbCx - pbW * 0.5
                        let y0 = pbCy - pbH * 0.5
                        objects.append(Object(x: x0, y: y0, w: pbW, h: pbH, label: classIndex, prob: confidence))
                    }
                }
            }
        }
        return objects
    }
    
    func nmsSortedBboxes(from proposals: [Object]) -> [Object] {
        var picked: [Object] = []
        for a in proposals {
            var keep = true
            for b in picked {
                let interArea = Object.interArea(a, b)
                let unionArea = a.area + b.area - interArea
                if interArea / unionArea > nmsThreshold {
                    keep = false
                    break
                }
            }
            if keep {
                picked.append(a)
            }
        }
        return picked
    }
    
    // MARK: constants
    let probThreshold: Float = 0.25
    let nmsThreshold: Float = 0.45
    let anchorDict: [Int: [Float]] = [
        8: [10.0, 13.0, 16.0, 30.0, 33.0, 23.0],
        16: [30.0, 61.0, 62.0, 45.0, 59.0, 119.0],
        32: [116.0, 90.0, 156.0, 198.0, 373.0, 326.0]
    ]
}

func sigmoid(x: Float) -> Float {
    return 1.0 / (1.0 + exp(-x))
}

let labels = [
    "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train",
    "truck", "boat", "traffic light", "fire hydrant", "stop sign",
    "parking meter", "bench", "bird", "cat", "dog", "horse", "sheep",
    "cow", "elephant", "bear", "zebra", "giraffe", "backpack",
    "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis",
    "snowboard", "sports ball", "kite", "baseball bat", "baseball glove",
    "skateboard", "surfboard", "tennis racket", "bottle", "wine glass",
    "cup", "fork", "knife", "spoon", "bowl", "banana", "apple",
    "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza",
    "donut", "cake", "chair", "couch", "potted plant", "bed",
    "dining table", "toilet", "tv", "laptop", "mouse", "remote",
    "keyboard", "cell phone", "microwave", "oven", "toaster",
    "sink", "refrigerator", "book", "clock", "vase",
    "scissors", "teddy bear", "hair drier", "toothbrush"
]
