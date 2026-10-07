//
//  AppBackground.swift
//  BonOdori
//
//  Created by Ringo Wathelet on 2026/09/18.
//
import SwiftUI


struct AppBackground: View {

    private var points: [SIMD2<Float>] {
        [
            .init(0.00, 0.00), .init(0.50, 0.00), .init(1.00, 0.00),
            .init(0.00, 0.52), .init(0.56, 0.46), .init(1.00, 0.48),
            .init(0.00, 1.00), .init(0.50, 1.00), .init(1.00, 1.00)
        ]
    }

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: points,
            colors: [
                .indigo.opacity(0.2), .blue.opacity(0.2), .cyan.opacity(0.3),
                .purple.opacity(0.2), .pink.opacity(0.2), .teal.opacity(0.3),
                .orange.opacity(0.3), .yellow.opacity(0.2), .mint.opacity(0.3)
            ],
            background: .black,
            smoothsColors: true,
            colorSpace: .perceptual
        )
    }
}
