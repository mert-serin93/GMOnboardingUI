//
//  OnboardingConfiguration.swift
//  GMOnboardingUI
//
//  Created by Mert Serin on 2025-01-27.
//

import SwiftUI
import UIKit

public struct OnboardingConfiguration {
    let primaryFont: UIFont
    let secondaryFont: UIFont
    let ctaFont: UIFont

    public init(primaryFont: UIFont, secondaryFont: UIFont, ctaFont: UIFont) {
        self.primaryFont = primaryFont
        self.secondaryFont = secondaryFont
        self.ctaFont = ctaFont
    }

    public static func mock() -> Self {
        return OnboardingConfiguration(primaryFont: .systemFont(ofSize: 18, weight: .semibold),
                                       secondaryFont: .systemFont(ofSize: 16, weight: .regular),
                                       ctaFont: .systemFont(ofSize: 17, weight: .semibold))
    }

    func getFont(from style: FontStyle, size: CGFloat) -> Font {
        switch style {
        case .primary: return .custom(primaryFont.fontName, size: size)
        case .secondary: return .custom(secondaryFont.fontName, size: size)
        case .cta:return .custom(ctaFont.fontName, size: size)
        }
    }
}
