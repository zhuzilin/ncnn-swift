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
    let time: Double
    
    init() {
        net = Yolov5()
        image = UIImage(named: "dogs")!
        if let net = net {
            let tmp = net.predict(for: image)
            results = tmp.0
            time = tmp.1
        } else {
            results = []
            time = -1
        }
    }

    var body: some View {
        VStack {
            if net != nil {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(Frame(frames: results, image: image))
                Text("time: \(String(format: "%.2fms", time))")
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

    var resize: CGSize {
        var w: CGFloat = image.size.width
        var h: CGFloat = image.size.height
        if w < h {
            w = CGFloat(Int(w / h * maxLength / 32) * 32)
            h = maxLength
        } else {
            h = CGFloat(Int(h / w * maxLength / 32) * 32)
            w = maxLength
        }
        return CGSize(width: w, height: h)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<frames.count) { i in
                    frame(frame: frames[i],
                          scaleX: geometry.size.width / resize.width,
                          scaleY: geometry.size.height / resize.height)
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
