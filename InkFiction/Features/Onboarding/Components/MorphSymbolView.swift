//
//  MorphSymbolView.swift
//  InkFiction
//
//  Animated morphing SF Symbol view for onboarding
//

import SwiftUI

// MARK: - Configuration

struct MorphSymbolConfiguration {
    let font: Font
    let frame: CGSize
    let radius: CGFloat
    let foregroundColor: Color
    let keyFrameDuration: Double

    static let `default` = MorphSymbolConfiguration(
        font: .system(size: 80, weight: .bold),
        frame: CGSize(width: 120, height: 120),
        radius: 15,
        foregroundColor: .primary,
        keyFrameDuration: 0.4
    )
}

// MARK: - Morph Symbol View

struct MorphSymbolView: View {
    let symbol: String
    let config: MorphSymbolConfiguration

    @State private var currentSymbol: String = ""
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            if #available(iOS 17.0, *) {
                Image(systemName: currentSymbol)
                    .font(config.font)
                    .foregroundColor(config.foregroundColor)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: config.frame.width, height: config.frame.height)
            } else {
                Image(systemName: currentSymbol)
                    .font(config.font)
                    .foregroundColor(config.foregroundColor)
                    .frame(width: config.frame.width, height: config.frame.height)
                    .animation(.easeInOut(duration: config.keyFrameDuration), value: currentSymbol)
            }
        }
        .onAppear {
            currentSymbol = symbol
        }
        .onChange(of: symbol) { _, newValue in
            withAnimation(.easeInOut(duration: config.keyFrameDuration)) {
                currentSymbol = newValue
            }
        }
    }
}
