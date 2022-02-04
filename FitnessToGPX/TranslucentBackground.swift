//
//  TranslucentBackground.swift
//  FitnessToGPX
//
//  Created by Sergej Jaskiewicz on 04.02.2022.
//

import SwiftUI

struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

extension View {
    func translucentBackground(style: UIBlurEffect.Style = .systemMaterial) -> some View {
        background(Blur(style: style))
    }
}
