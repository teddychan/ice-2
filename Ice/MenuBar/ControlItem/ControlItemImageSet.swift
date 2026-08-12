//
//  ControlItemImageSet.swift
//  Ice
//

import DragonKit

/// A named set of images that are used by control items.
///
/// An image set contains images for a control item in both the hidden and visible states.
struct ControlItemImageSet: Codable, Hashable, Identifiable {
    enum Name: String, Codable, Hashable {
        case arrow = "Arrow"
        case chevron = "Chevron"
        case door = "Door"
        case dot = "Dot"
        case ellipsis = "Ellipsis"
        case iceCube = "Ice Cube"
        case sunglasses = "Sunglasses"
        case custom = "Custom"

        /// The name as shown in the icon chooser. `rawValue` is `Codable`-persisted, so it
        /// stays English and the display name is resolved separately.
        @MainActor var localized: String {
            switch self {
            case .arrow: L("app.icon.arrow")
            case .chevron: L("app.icon.chevron")
            case .door: L("app.icon.door")
            case .dot: L("app.icon.dot")
            case .ellipsis: L("app.icon.ellipsis")
            case .iceCube: L("app.icon.iceCube")
            case .sunglasses: L("app.icon.sunglasses")
            case .custom: L("app.icon.custom")
            }
        }
    }

    let name: Name
    let hidden: ControlItemImage
    let visible: ControlItemImage

    var id: Int { hashValue }

    init(name: Name, hidden: ControlItemImage, visible: ControlItemImage) {
        self.name = name
        self.hidden = hidden
        self.visible = visible
    }

    init(name: Name, image: ControlItemImage) {
        self.init(name: name, hidden: image, visible: image)
    }
}

extension ControlItemImageSet {
    /// The default image set for the Ice icon.
    static let defaultIceIcon = ControlItemImageSet(
        name: .dot,
        hidden: .catalog("DotFill"),
        visible: .catalog("DotStroke")
    )

    /// The image sets that the user can choose to display in the Ice icon.
    static let userSelectableIceIcons = [
        ControlItemImageSet(
            name: .arrow,
            hidden: .symbol("arrowshape.left.fill"),
            visible: .symbol("arrowshape.right.fill")
        ),
        ControlItemImageSet(
            name: .chevron,
            hidden: .symbol("chevron.left"),
            visible: .symbol("chevron.right")
        ),
        ControlItemImageSet(
            name: .door,
            hidden: .symbol("door.left.hand.closed"),
            visible: .symbol("door.left.hand.open")
        ),
        ControlItemImageSet(
            name: .dot,
            hidden: .catalog("DotFill"),
            visible: .catalog("DotStroke")
        ),
        ControlItemImageSet(
            name: .ellipsis,
            hidden: .catalog("EllipsisFill"),
            visible: .catalog("EllipsisStroke")
        ),
        ControlItemImageSet(
            name: .iceCube,
            hidden: .catalog("IceCubeStroke"),
            visible: .catalog("IceCubeFill")
        ),
        ControlItemImageSet(
            name: .sunglasses,
            hidden: .symbol("sunglasses.fill"),
            visible: .symbol("sunglasses")
        ),
    ]
}
