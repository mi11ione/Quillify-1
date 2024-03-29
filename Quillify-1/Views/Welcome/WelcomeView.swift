//
//  WelcomeView.swift
//  Quillify-1
//
//  Created by mi11ion on 19/3/24.
//

import SwiftUI

struct WelcomeView: View {
    @ObservedObject var windowState: WindowState
    @State var welcomeState: WelcomeState = .welcomeMessage
    
    var body: some View {
        ZStack {
            ScrollView {
                switch welcomeState {
                case .welcomeMessage:
                    WelcomeMessageView()
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading).combined(with: .opacity)))
                case .learnTools:
                    LearnToolsView()
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading).combined(with: .opacity)))
                case .selectPhoto:
                    PhotoPickerView(windowState: windowState)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading).combined(with: .opacity)))
                }
            }
            
            if welcomeState != .selectPhoto {
                VStack{
                    Spacer()
                    Button(action: { self.buttonAction() }) {
                        Text(self.buttonMessage())
                            .font(.headline)
                            .bold()
                            .foregroundColor(Color(uiColor: UIColor.systemBackground))
                            .padding()
                            .frame(width: 200)
                            .background(Color.accentColor)
                            .cornerRadius(15)
                    }
                    .padding(.bottom, 40)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    func buttonAction() {
        switch welcomeState {
        case .welcomeMessage:
            withAnimation { self.welcomeState = .learnTools }
        case .learnTools:
            withAnimation { self.welcomeState = .selectPhoto }
        case .selectPhoto:
            break
        }
    }
    
    func buttonMessage() -> String {
        switch welcomeState {
        case .welcomeMessage:
            return "Интересно"
        case .learnTools:
            return "Го рисовать"
        case .selectPhoto:
            return ""
        }
    }
}
