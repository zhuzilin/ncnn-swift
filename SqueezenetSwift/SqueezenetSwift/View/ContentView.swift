//
//  ContentView.swift
//  SwiftNCNN
//
//  Created by Zilin Zhu on 2021/1/28.
//

import SwiftUI

struct ContentView: View {
    let net: Squeezenet?
    let image: UIImage
    var results: [(String, Float)] = []
    
    init() {
        net = Squeezenet()
        image = UIImage(named: "Persian_cat")!

        if let net = net {
            results = net.predict(for: image, top: 3)
                .map {(net.label[$0.0]!, $0.1)}
        }
    }

    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
            if net == nil {
                Text("Failed to load ncnn net.")
            } else {
                ForEach(0..<results.count) { i in
                    Text(String(format: "%@ %.2f%%", results[i].0, results[i].1 * 100))
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
