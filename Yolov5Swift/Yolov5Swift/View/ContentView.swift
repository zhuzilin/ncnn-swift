//
//  ContentView.swift
//  Yolov5Swift
//
//  Created by Zilin Zhu on 2021/1/30.
//

import SwiftUI

struct ContentView: View {
    let net: Yolov5?
    let image: UIImage
    let results: [Object]

    init() {
        net = Yolov5()
        // Yolo requires the width and height of the image are both multiplier of 32.
        let rawImage = UIImage(named: "dogs")!
        var w = rawImage.size.width
        var h = rawImage.size.height
        if w < h {
            w = CGFloat(Int(w / h * 640 / 32) * 32)
            h = 640
        } else {
            h = CGFloat(Int(h / w * 640 / 32) * 32)
            w = 640
        }
        image = rawImage.resize(targetSize:
                                    CGSize(width: w, height: h))
        if let net = net {
            results = net.predict(for: image)
        } else {
            results = []
        }
    }

    var body: some View {
        VStack {
            if net != nil {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(Frame(frames: results, image: image))
            } else {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Text("Failed to load net")
            }
        }
    }
}

struct Frame: View {
    let frames: [Object]
    let image: UIImage

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<frames.count) { i in
                    frame(frame: frames[i],
                          scaleX: geometry.size.width / image.size.width,
                          scaleY: geometry.size.height / image.size.height)
                }
            }
        }
    }
    
    func frame(frame: Object, scaleX: CGFloat, scaleY: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .path(in: CGRect(x: CGFloat(frame.x) * scaleX,
                                 y: CGFloat(frame.y) * scaleY,
                                 width: CGFloat(frame.w) * scaleX,
                                 height: CGFloat(frame.h) * scaleY))
                .stroke(lineWidth: 3.0)
                .foregroundColor(.red)
            Text("\(labels[frame.label]) \(String(format: "%.2f", frame.prob*100))%")
                .padding(3)
                .foregroundColor(.black)
                .offset(x: CGFloat(frame.x) * scaleX,
                        y: CGFloat(frame.y) * scaleY - 25)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
