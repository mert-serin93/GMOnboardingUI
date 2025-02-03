//
//  OnboardingScreenItem.swift
//  GMOnboarding
//
//  Created by Mert Serin on 2024-10-25.
//

import Foundation
import SwiftUI

struct OnboardingScreenItem: Codable, Identifiable {

    enum ItemType: String, Codable {
        case spacer, text, image, button, video, backgroundView, progress, gradient

    }

    let id: String
    let name: String
    var type: ItemType
    let itemJSON: String?
    var item: (any GMOnboardingItem)?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case itemJSON
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(ItemType.self, forKey: .type)
        itemJSON = try container.decodeIfPresent(String.self, forKey: .itemJSON)
        item = nil

        guard let itemJSON = itemJSON?.replacingOccurrences(of: "", with: "\\"), let data = itemJSON.data(using: .utf8) else { return }

        switch type {
        case .text:
            self.item = try JSONDecoder().decode(ItemText.self, from: data)
        case .button:
            self.item = try JSONDecoder().decode(ItemButton.self, from: data)
        case .backgroundView:
            self.item = try JSONDecoder().decode(ItemBackgroundView.self, from: data)
        default:
            item = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)

        if let item = item {
            do {
                let jsonData = try JSONEncoder().encode(item)
                let jsonString = String(data: jsonData, encoding: .utf8)
                try container.encode(jsonString, forKey: .itemJSON)
            } catch {
                print("Mert11: ", error)
            }

        }
    }

    init(id: String, name: String, type: ItemType, itemJSON: String?, item: (any GMOnboardingItem)?) {
        self.id = id
        self.name = type.rawValue.capitalized
        self.type = type
        self.itemJSON = itemJSON
        self.item = item
    }

    init(item: OnboardingScreenItem) {
        self.id = item.id
        self.name = item.name
        self.type = item.type
        self.item = item.item
        if let data = try? JSONEncoder().encode(item) {
            self.itemJSON = String(data: data, encoding: .utf8)
        } else {
            self.itemJSON = nil
        }
    }

    static func mock() -> Self {
        return Self(id: UUID().uuidString, name: "Item", type: .text, itemJSON: nil, item: ItemText.create())
    }

    static func mockSpacer() -> Self {
        return Self(id: UUID().uuidString, name: "Spacer", type: .spacer, itemJSON: nil, item: nil)
    }

    func copy() -> Self {
        let newItem = self.item?.copy()
        var newItemJSON: String?
        if let newItem, let data = try? JSONEncoder().encode(newItem) {
            newItemJSON = String(data: data, encoding: .utf8)
        }
        return Self(id: UUID().uuidString, name: name, type: type, itemJSON: newItemJSON, item: newItem)
    }
}

enum TextAlignment: String, Codable {
    case center, left, right

    func toAlignment() -> Alignment {
        switch self {
        case .center:
            return .center
        case .left:
            return .leading
        case .right:
            return .trailing
        }
    }

    func toTextAlignment() -> SwiftUI.TextAlignment {
        switch self {
        case .center:
            return .center
        case .left:
            return .leading
        case .right:
            return .trailing
        }
    }
}

protocol GMOnboardingItem: Identifiable, Codable {
    var id: String { get set }
    var backgroundColor: String { get set }
    func copy() -> Self
}

protocol GMOnboardingCustomizableItem: GMOnboardingItem {
    var text: String { get set }
    var fontSize: CGFloat { get set }
    var fontWeight: String { get set }
    var fontColor: String { get set }
    var alignment: TextAlignment { get set }
    var font: String { get set }
    var padding: ItemPadding { get set }
}

struct ItemText: GMOnboardingCustomizableItem {
    var id: String
    var text: String
    var fontSize: CGFloat
    var fontWeight: String
    var fontColor: String
    var alignment: TextAlignment
    var font: String
    var padding: ItemPadding
    var backgroundColor: String
    var fontStyle: String?

    static func create() -> Self {
        return ItemText(id: UUID().uuidString, text: "Text", fontSize: 18, fontWeight: "Regular", fontColor: "#000000", alignment: .center, font: "SFProText", padding: .make(), backgroundColor: "#00000000", fontStyle: "primary")
    }

    func getFont() -> String {
        return "\(font)-\(fontWeight)"
    }

    func getFontWeight() -> Font.Weight {
        if fontWeight == "Regular" {
            return .regular
        } else if fontWeight == "Medium" {
            return .medium
        } else if fontWeight == "Bold" {
            return .bold
        } else if fontWeight == "Heavy" {
            return .heavy
        } else if fontWeight == "Black" {
            return .black
        } else if fontWeight == "Light" {
            return .light
        } else if fontWeight == "Thin" {
            return .thin
        } else if fontWeight == "Semibold" {
            return .semibold
        }
        return .regular
    }

    func copy() -> Self {
        return Self(id: UUID().uuidString, text: text, fontSize: fontSize, fontWeight: fontWeight, fontColor: fontColor, alignment: alignment, font: font, padding: padding, backgroundColor: backgroundColor, fontStyle: fontStyle)
    }
}

struct ItemButton: GMOnboardingCustomizableItem {
    var id: String
    var text: String
    var fontSize: CGFloat
    var fontWeight: String
    var fontColor: String
    var alignment: TextAlignment
    var font: String
    var backgroundColor: String
    var padding: ItemPadding
    var cornerRadius: Double
    var fontStyle: String?

    static func create() -> Self {
        return ItemButton(id: UUID().uuidString, text: "Text", fontSize: 18, fontWeight: "Regular", fontColor: "#000000", alignment: .center, font: "SFProText", backgroundColor: "#333333", padding: .make(), cornerRadius: 20, fontStyle: "cta")
    }

    func copy() -> Self {
        return Self(id: UUID().uuidString, text: text, fontSize: fontSize, fontWeight: fontWeight, fontColor: fontColor, alignment: alignment, font: font, backgroundColor: backgroundColor, padding: padding, cornerRadius: cornerRadius, fontStyle: fontStyle)
    }
}

struct ItemBackgroundView: GMOnboardingItem {
    enum BGViewType: String, Codable {
        case image, video, none
    }

    var id: String
    var backgroundColor: String
    var data: Data?
    var url: String?
    var type: BGViewType

    static func create() -> Self {
        return Self(id: UUID().uuidString, backgroundColor: "#000000", data: nil, url: nil, type: .none)
    }

    func copy() -> Self {
        return Self(id: UUID().uuidString, backgroundColor: backgroundColor, data: data, url: url, type: type)
    }

    func copy(with url: String?, type: String) -> Self {
        return Self(id: UUID().uuidString, backgroundColor: backgroundColor, data: data, url: url ?? self.url, type: BGViewType(rawValue: type) ?? self.type)
    }
}

struct ItemPadding: Codable {
    var leading: Double
    var trailing: Double
    var top: Double
    var bottom: Double

    static func make() -> Self {
        return Self(leading: 20, trailing: 20, top: 0, bottom: 20)
    }

    func makeEdgeInsets() -> EdgeInsets {
        return EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }
}

struct ItemSize: Codable {
    var width: Double
    var height: Double

    static func make() -> Self {
        return Self(width: 200, height: 200)
    }
}

struct ItemImage: GMOnboardingItem {
    var id: String
    var padding: ItemPadding
    var size: ItemSize
    var url: String?
    var backgroundColor: String
    var cornerRadius: Double

    static func create() -> Self {
        return ItemImage(id: UUID().uuidString, padding: .make(), size: .make(), url: nil, backgroundColor: "#000000", cornerRadius: 0)
    }

    func copy() -> Self {
        return ItemImage(id: UUID().uuidString, padding: padding, size: size, url: url, backgroundColor: backgroundColor, cornerRadius: cornerRadius)
    }
}

enum FontStyle: String, Codable, CaseIterable, Identifiable {
    case primary, secondary, cta

    var id: String { rawValue }
}
