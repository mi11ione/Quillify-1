//
//  CanvasDrawView.swift
//  Quillify-1
//
//  Created by mi11ion on 19/3/24.
//

import SwiftUI

struct CanvasDrawView: View {
    @ObservedObject var windowState: WindowState
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    @State var showingFinalizeView: Bool = false
    
    let colorColumns = [
        GridItem(.adaptive(minimum: 30))
    ]
    
    // Get the first three colors that are in the selection
    var selectionColorIndices: [(index: Int, color: UIColor)] {
        let colors = Array(windowState.selectionColors).enumerated().filter { index, color in
            index < 3
        }.map { $0.1 }
        return Array(zip(colors.indices, colors))
    }
    
    var hasSelection: Bool {
        windowState.selection != nil
    }
    
    // Give adequate space to 3 vs 5 tools
    var toolWidth: CGFloat {
        hasSelection ? 250 : 400
    }
    
    var body: some View {
        ZStack{
            LibraryPhotoPickerView(windowState: windowState)
            Rectangle()
                .foregroundColor(Color(uiColor: UIColor.systemGray6))
                .transition(.opacity)
                .ignoresSafeArea()
            CanvasView(windowState: windowState)
                .transition(.opacity)
                .ignoresSafeArea()
            VStack{
                if horizontalSizeClass == .compact {
                    Spacer()
                    self.penColorPicker()
                        .zIndex(0)
                        .padding()
                    self.selectionColorPicker()
                        .zIndex(0)
                        .padding()
                }
                if windowState.currentTool != .placePhoto {
                    ZStack {
                        RoundedRectangle(cornerRadius: .greatestFiniteMagnitude, style: .continuous)
                            .foregroundColor(Color(uiColor: UIColor.systemGray5))
                        HStack {
                            Spacer()
                            if windowState.currentTool != .placePhoto {
                                if !hasSelection {
                                    self.controls()
                                }
                                Button(action: {selectionAction()}) {
                                    Image(systemName: "lasso")
                                        .font(.largeTitle)
                                        .foregroundColor(windowState.currentTool == .selection ? .primary : .secondary)
                                        .frame(width: 50)
                                }
                                .accessibilityLabel("Выделение")
                                .accessibility(addTraits: self.windowState.currentTool == .selection ? .isSelected : [])
                                if hasSelection {
                                    Spacer()
                                    self.selectionControls()
                                }
                            }
                            Spacer()
                        }
                    }
                    .frame(minWidth: nil, idealWidth: toolWidth, maxWidth: toolWidth, minHeight: nil, idealHeight: 70, maxHeight: 70, alignment: .center)
                    .transition(.opacity.combined(with: .move(edge: self.horizontalSizeClass == .compact ? .bottom : .top)))
                    .zIndex(1)
                    .padding(.horizontal)
                }
                if horizontalSizeClass != .compact {
                    self.penColorPicker()
                        .zIndex(0)
                        .padding()
                    self.selectionColorPicker()
                        .zIndex(0)
                        .padding()
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder func controls() -> some View {
        Button(action: {windowState.currentTool = .touch}) {
            Image(systemName: "hand.point.up")
                .font(.largeTitle)
                .foregroundColor(windowState.currentTool == .touch ? .primary : .secondary)
                .frame(width: 50)
        }
        .accessibilityLabel("Касание")
        .accessibility(addTraits: self.windowState.currentTool == .touch ? .isSelected : [])
        Spacer()
        Button(action: {penAction()}) {
            ZStack {
                Image(systemName: "pencil.tip")
                    .font(.largeTitle)
                    .foregroundColor(windowState.currentTool == .pen ? .primary : .secondary)
                // Overlay selected color
                Image(systemName: "pencil.tip")
                    .font(.largeTitle)
                    .foregroundColor(Color(uiColor: windowState.currentColor.color))
                    .mask(VStack{
                        Rectangle()
                            .foregroundColor(.white)
                            .frame(height: 15)
                        Spacer()
                    })
                    .opacity(windowState.currentTool == .pen ? 100 : 0)
            }
            .frame(width: 50)
        }
        .accessibilityLabel("Pen")
        .accessibilityValue(Text(windowState.currentColor.name(isDark: colorScheme == .dark)))
        .accessibility(addTraits: self.windowState.currentTool == .pen ? .isSelected : [])
        Spacer()
        Menu {
            Button(action: {
                self.windowState.photoMode = .cameraScan
            }) {
                Label("Сканирование", systemImage: "viewfinder")
            }
            Button(action: {
                self.windowState.photoMode = .library
            }) {
                Label("Галерея", systemImage: "photo.fill")
            }
            
            Button(action: {
                self.windowState.photoMode = .example
            }) {
                Label("Демо", systemImage: "photo.on.rectangle.angled")
            }
        } label: {
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundColor(.accentColor)
            
                .frame(width: 50)
        }
        .accessibilityLabel("Добавить фото")
        Spacer()
        Button(action: {windowState.currentTool = .remove}) {
            ZStack{
                Image(systemName: "scribble")
                    .font(.largeTitle)
                    .foregroundColor(windowState.currentTool == .remove ? .primary : .secondary)
                Image(systemName: "line.diagonal")
                    .font(.largeTitle)
                    .foregroundColor(windowState.currentTool == .remove ? Color.red : Color(uiColor: UIColor.systemGray3))
                
            }
            .frame(width: 50)
        }
        .accessibilityLabel("Убрать")
        .accessibility(addTraits: self.windowState.currentTool == .remove ? .isSelected : [])
        Spacer()
    }
    
    @ViewBuilder func penColorPicker() -> some View {
        if self.windowState.isShowingPenColorPicker {
            LazyVGrid(columns: colorColumns, spacing: 15) {
                ForEach(SemanticColor.allCases, id: \.self) { color in
                    Button(action: { self.windowState.currentColor = color  }) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .foregroundColor(Color(uiColor: color.color))
                            .frame(width: 30, height: 30)
                            .overlay{
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(Color.accentColor, lineWidth: self.windowState.currentColor == color ? 3 : 0)
                            }
                    }
                    .accessibilityLabel(Text(color.name(isDark: colorScheme == .dark)))
                    .accessibility(addTraits: self.windowState.currentColor == color ? .isSelected : [])
                }
            }
            .padding()
            .background{
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .foregroundColor(Color(uiColor: .systemGray5))
            }
            .frame(minWidth: nil, idealWidth: 200, maxWidth: 200, alignment: .center)
            .transition(.scale.combined(with: .opacity).combined(with: .move(edge: self.horizontalSizeClass == .compact ? .bottom : .top)))
        }
    }
    
    @ViewBuilder func selectionColorPicker() -> some View {
        if self.windowState.isShowingSelectionColorPicker {
            LazyVGrid(columns: colorColumns, spacing: 15) {
                ForEach(SemanticColor.allCases, id: \.self) { color in
                    Button(action: { try? self.windowState.recolorSelection(newColor: color) }) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .foregroundColor(Color(uiColor: color.color))
                            .frame(width: 30, height: 30)
                            .overlay{
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(Color.accentColor, lineWidth: selectionIsColor(color) ? 3 : 0)
                            }
                    }
                    .accessibilityLabel(Text(color.name(isDark: colorScheme == .dark)))
                    .accessibility(addTraits: selectionIsColor(color) ? .isSelected : [])
                }
            }
            .padding()
            .background{
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .foregroundColor(Color(uiColor: .systemGray5))
            }
            .frame(minWidth: nil, idealWidth: 200, maxWidth: 200, alignment: .center)
            .transition(.scale.combined(with: .opacity).combined(with: .move(edge: self.horizontalSizeClass == .compact ? .bottom : .top)))
        }
    }
    
    @ViewBuilder func selectionControls() -> some View {
        Button(action: { withAnimation{ windowState.isShowingSelectionColorPicker.toggle() }}) {
            ZStack {
                // Display the colors of the paths that are selected
                ForEach(selectionColorIndices, id: \.index) { index, color in
                    Circle()
                        .foregroundColor(Color(uiColor: color))
                        .frame(height: 30)
                        .overlay{
                            Circle()
                                .stroke(Color(uiColor: .systemGray5), lineWidth: 3)
                        }
                        .offset(x: CGFloat(index) * -10)
                }
            }
            .offset(x: CGFloat(selectionColorIndices.count - 1) * 5)
            .frame(width: 50, height: 50)
        }
        .accessibilityLabel("Изменить цвет")
        Spacer()
        Button(action: { try? windowState.removeSelectionPaths() }) {
            ZStack{
                Image(systemName: "scribble")
                    .font(.largeTitle)
                    .foregroundColor(.primary)
                Image(systemName: "line.diagonal")
                    .font(.largeTitle)
                    .foregroundColor(Color.red)
            }
            .frame(width: 50)
        }
        .accessibilityLabel("Убрать пути")
    }
    
    private func selectionIsColor(_ color: SemanticColor) -> Bool {
        windowState.selectionColors.count == 1 && windowState.pencilSelectionColors.contains(color.pencilKitColor)
    }
    
    private func penAction() -> Void {
        if windowState.currentTool == .pen {
            withAnimation{windowState.isShowingPenColorPicker.toggle()}
        } else {
            windowState.currentTool = .pen
        }
    }
    
    private func selectionAction() -> Void {
        if windowState.currentTool == .selection {
            withAnimation{ windowState.selection = nil }
        } else {
            windowState.currentTool = .selection
        }
    }
}
