//
//  ManualTypes.swift
//
//
//  Created by Kit Transue on 2022-09-06.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//


public struct IndexedScene: Codable, Sendable {
    public let sceneIndex: Int
    public let sceneName: String
}

public struct IndexedSceneItem: Codable, Sendable {
    public let sceneItemId: Int
    public let sceneItemIndex: Int
}

public struct SceneSource: Codable, Equatable, Sendable {
    public let sceneItemId: Int
    public let sceneItemIndex: Int
    public let sourceName: String
    public let sceneItemTransform: SceneItemTransform

    public let inputKind: String
    public let sourceType: String
    // isGroup  // optional type unclear
    public let sceneItemLocked: Bool
    public let sceneItemEnabled: Bool
}

public enum OBSBoundsType: String, Codable, Sendable {
    case none = "OBS_BOUNDS_NONE"
}

public enum ItemAlignment: Int, Codable, Sendable {
    case topLeft = 5
    case topCenter = 4
    case topRight = 6
    case centerLeft = 1
    case center = 0
    case centerRight = 2
    case bottomLeft = 9
    case bottomCenter = 8
    case bottomRight = 10
}

// FIXME: split into request and response; options like width don't have effect in request; research and remove
// FIXME: OR: remove read-only items from public initializer...
public struct SceneItemTransform: Codable, Equatable, Sendable {
    public let alignment: ItemAlignment?
    public let boundsAlignment: Int?
    public let boundsHeight: Double?
    public let boundsType: OBSBoundsType?
    public let boundsWidth: Double?
    public let cropBottom: Int?  // applied before scale, not factored in width
    public let cropLeft: Int?
    public let cropRight: Int?
    public let cropTop: Int?
    /// Height an uncropped source would be in output pixels: sourceHeight * scaleY; crop not factored
    ///
    /// - Note: experience seems to be this is **read-only**
    public let height: Double?
    /// Output coordinate to place first visible (cropped) pixel of source
    public let positionX: Double?
    public let positionY: Double?
    public let rotation: Double?
    public let scaleX: Double?
    public let scaleY: Double?
    /// For Retina screen captures, this seems to be the actual pixel count, not the pixel
    /// count provided to the application; e.g. 4480x2250 for a 4.5k iMac capture.
    ///
    /// Presumably read-only
    public let sourceHeight: Double?
    /// For Retina screen captures, this seems to be the actual pixel count, not the pixel
    /// count provided to the application; e.g. 4480x2250 for a 4.5k iMac capture.
    ///
    /// Presumably read-only
    public let sourceWidth: Double?
    /// Width an uncropped source would be in output pixels: sourceWidth * scaleX; crop not factored
    ///
    /// - Note: experience seems to be this is **read-only**
    public let width: Double?

    // FIXME: arrange topically by usage?
    public init(alignment: ItemAlignment? = nil,
         boundsAlignment: Int? = nil, boundsHeight: Double? = nil,
         boundsType: OBSBoundsType? = nil, boundsWidth: Double? = nil,
         cropBottom: Int? = nil, cropLeft: Int? = nil, cropRight: Int? = nil,
         cropTop: Int? = nil,
         height: Double? = nil,
         positionX: Double? = nil, positionY: Double? = nil,
         rotation: Double? = nil, scaleX: Double? = nil, scaleY: Double? = nil,
         sourceHeight: Double? = nil, sourceWidth: Double? = nil, width: Double? = nil) {
        self.alignment = alignment
        self.boundsAlignment = boundsAlignment
        self.boundsHeight = boundsHeight
        self.boundsType = boundsType
        self.boundsWidth = boundsWidth
        self.cropBottom = cropBottom
        self.cropLeft = cropLeft
        self.cropRight = cropRight
        self.cropTop = cropTop
        self.height = height
        self.positionX = positionX
        self.positionY = positionY
        self.rotation = rotation
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.sourceHeight = sourceHeight
        self.sourceWidth = sourceWidth
        self.width = width
    }
}

extension SceneItemTransform {
    public var croppedWidth: Double? {get {
        guard let sourceWidth = sourceWidth,
              let cropLeft = cropLeft, let cropRight = cropRight else {
            return nil
        }
        return sourceWidth - Double(cropLeft + cropRight)
    }}
    public var croppedHeight: Double? {get {
        guard let sourceHeight = sourceHeight,
              let cropBottom = cropBottom, let cropTop = cropTop else {
            return nil
        }
        return sourceHeight - Double(cropTop + cropBottom)
    }}
}

public struct KeyModifiers: Codable, Sendable {
    let shift: Bool?
    let control: Bool?
    let alt: Bool?
    let command: Bool?
}

public extension EventSubscription {
    /// Events that are not included in ``allLowVolume`` because of their frequency. Excludes ``inputVolumeMeters`` (which are overwhelmingly frequent).
    static let verbose: Self = [.inputActiveStateChanged, .inputShowStateChanged, .sceneItemTransformChanged]
    
    /// Synonym for OBS ``all``. These both exclude high-volume ``verbose`` messages.
    static let allLowVolume = Self.all
}
