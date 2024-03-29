//
//  WindowState.swift
//  Quillify-1
//
//  Created by mi11ion on 19/3/24.
//

import Combine
import SwiftUI
import PencilKit

class WindowState: ObservableObject {
    // The color of the pen tool
    @Published var currentColor: SemanticColor = .primary
    @Published var currentTool: CanvasTool = .pen {
        willSet {
            Task { @MainActor in
                // No longer in selection mode, remove selection
                if newValue != CanvasTool.selection {
                    self.selection = nil
                }
                // No longer in pen mode, dismiss the pen color picker
                if newValue != CanvasTool.pen {
                    withAnimation{ self.isShowingPenColorPicker = false }
                }
            }
        }
    }
    
    // Store the indices of the selected strokes in the drawing's strokes array
    @Published var selection: Set<Int>? = nil {
        // Selection changed, the selection color picker should not be visible
        willSet {
            Task { @MainActor in
                withAnimation{ self.isShowingSelectionColorPicker = false }
            }
            
        }
    }
    @Published var isShowingPenColorPicker: Bool = false
    @Published var isShowingSelectionColorPicker: Bool = false
    @Published var photoMode: PhotoMode = .welcome
    
    @Published var finalizeImage: UIImage? = nil
    var imageConversion: ImageConversion? = nil
    // Notify when the image conversion has completed
    var imageCancellable: AnyCancellable? = nil
    
    // Used to know where to place the image
    weak var canvas: Canvas? = nil
    
    var hasSelection: Bool {
        self.selection != nil
    }
    
    var isShowingPopover: Bool {
        isShowingPenColorPicker || isShowingSelectionColorPicker
    }
    
    var selectedStrokes: [(Int, PKStroke)] {
        guard let selection = selection else { return [] }
        return canvas?.strokes.enumerated().filter({ index, stroke in
            return selection.contains(index)
        }) ?? []
    }
    
    var selectionColors: Set<UIColor> {
        var colors = Set<UIColor>()
        return self.selectedStrokes.reduce(into: Set<UIColor>(), { colorSet, path in
            let dynamicColor = SemanticColor.adaptiveInvertedBrightness(color: path.1.ink.color)
            guard !colors.contains(path.1.ink.color) else {
                return
            }
            colors.insert(path.1.ink.color)
            colorSet.insert(dynamicColor)
        })
    }
    
    // Colors that are equatable
    var pencilSelectionColors: Set<UIColor> {
        Set<UIColor>(selectionColors.map { $0.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))})
    }
    
    enum SelectionModifyError: Error {
        case noSelection
    }
    
    func addStrokes(strokes: [PKStroke]) {
        canvas?.addStrokes(strokes)
    }
    
    func recolorSelection(newColor: SemanticColor) throws -> Void {
        let recoloredStrokes = selectedStrokes.map { index, stroke in
            return (index, PKStroke(ink: PKInk(.pen, color: newColor.pencilKitColor), path: stroke.path, transform: stroke.transform, mask: stroke.mask))
        }
        self.canvas?.updateStrokes(recoloredStrokes)
        // Update the canvas with the new color
        objectWillChange.send()
    }
    
    func removeSelectionPaths() throws -> Void {
        guard let selection = selection else {
            throw SelectionModifyError.noSelection
        }
        self.removePaths(selection)
        withAnimation { self.selection = nil }
    }
    
    func removePaths(_ removeSet: Set<Int>) {
        self.canvas?.removeStrokes(removeSet)
    }
}

enum CanvasTool: Equatable {
    case touch
    case pen
    case remove
    case selection
    case placePhoto
}

enum PhotoMode {
    case welcome
    case none
    case cameraScan
    case library
    case example
}

/// Colors that a user can select
enum SemanticColor: CaseIterable, Comparable {
    // Supported colors
    case primary
    case gray
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    
    // light mode colors that dark mode colors are generated from
    private var lightColor: UIColor {
        switch self {
        case .primary:
            return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        case .gray:
            return #colorLiteral(red: 0.5568627451, green: 0.5568627451, blue: 0.5764705882, alpha: 1)
        case .red:
            return #colorLiteral(red: 0.9833723903, green: 0.1313590407, blue: 0.1335203946, alpha: 1)
        case .orange:
            return #colorLiteral(red: 0.999529779, green: 0.5594156384, blue: 0, alpha: 1)
        case .yellow:
            return #colorLiteral(red: 0.9696072936, green: 0.8020537496, blue: 0, alpha: 1)
        case .green:
            return #colorLiteral(red: 0.3882352941, green: 0.7921568627, blue: 0.337254902, alpha: 1)
        case .blue:
            return #colorLiteral(red: 0.03155988827, green: 0.4386033714, blue: 0.9659433961, alpha: 1)
        case .purple:
            return #colorLiteral(red: 0.6174378395, green: 0.2372990549, blue: 0.8458326459, alpha: 1)
        }
    }
    
    public var color: UIColor {
        Self.adaptiveInvertedBrightness(color: lightColor)
    }
    
    /// Color that changes depending on the system theme with an inverted brightness variant of the given color
    static func adaptiveInvertedBrightness(color: UIColor) -> UIColor {
        let lightMode = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let darkMode = Self.invertedBrightnessColor(color: lightMode)
        
        let provider: (UITraitCollection) -> UIColor = { traits in
            if traits.userInterfaceStyle == .dark {
                return darkMode
            } else {
                return lightMode
            }
        }
        return UIColor(dynamicProvider: provider)
    }
    
    /// Inverted brightness variant of the given color
    static func invertedBrightnessColor(color: UIColor) -> UIColor {
        let lightMode = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
    
        lightMode.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        lightMode.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        let inverted = UIColor(red: 1 - red, green: 1 - green, blue: 1 - blue, alpha: alpha)
        var invertedBrightness: CGFloat = 0
        inverted.getHue(nil, saturation: nil, brightness: &invertedBrightness, alpha: nil)
        
        return UIColor(hue: hue, saturation: saturation, brightness: invertedBrightness, alpha: alpha)
    }
    
    /// The light mode color that PencilKit uses to interpret light and dark mode colors
    public var pencilKitColor: UIColor {
        self.lightColor
    }
    
    /// Accessibility label for color
    public func name(isDark: Bool) -> String {
        switch self {
        case .primary:
            return isDark ? "White" : "Black"
        case .gray:
            return "Gray"
        case .red:
            return "Red"
        case .orange:
            return "Orange"
        case .yellow:
            return "Yellow"
        case .green:
            return "Green"
        case .blue:
            return "Blue"
        case .purple:
            return "Purple"
        }
    }
    
}

/// Photo that is being converted to a collection of paths
class ImageConversion: ObservableObject {
    let image: UIImage
    @Published var paths: [([CGPoint], UIColor)]? = nil
    
    lazy var scaleTransform: CGAffineTransform = {
        // Initially fit the image within a 400 point square
        let dimension: CGFloat = 400
        guard let cgImage = image.cgImage else { return .identity }
        let width = cgImage.width
        let height = cgImage.height
        let max: CGFloat = CGFloat(max(width, height))
        let scale = dimension / max
        let transform = CGAffineTransform.init(scaleX: scale, y: scale)
        return transform
    }()
    
    var translateTransform: CGAffineTransform
    
    var transform: CGAffineTransform {
        return scaleTransform.concatenating(translateTransform)
    }
    
    var isConversionFinished: Bool {
        paths != nil
    }
    
    init(image: UIImage, position: CGPoint) {
        self.image = image
        self.translateTransform = CGAffineTransform(translationX: position.x, y: position.y)
        let size = image.size
        // translate the image so that the image is centered on the canvas
        var rect: CGRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        rect = rect.applying(scaleTransform)
        self.translateTransform = translateTransform.translatedBy(x: -1 * CGFloat(rect.width) / 2, y: -1 * CGFloat(rect.height) / 2)
    }
    
    func applyTranslate(transform: CGAffineTransform) {
        self.translateTransform = self.translateTransform.concatenating(transform)
    }
    
    func applyScale(transform: CGAffineTransform) {
        self.scaleTransform = self.scaleTransform.concatenating(transform)
    }
}
