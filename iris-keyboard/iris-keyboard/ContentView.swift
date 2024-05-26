//
//  InputView.swift
//  iris-keyboard
//
//  Created by Yinka Adepoju on 25/5/24.
//

//
//  InputView.swift
//  iris-keyboard
//
//  Created by Yinka Adepoju on 25/5/24.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var text: String = ""
    @State private var textHeight: CGFloat = 40
    @State private var fontSize: CGFloat = 40
    @FocusState private var isFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    @State private var cancellable: AnyCancellable?
    @State private var isTextFieldVisible: Bool = true
    
    private var buttonSize: CGFloat = 48
    private let characterLimit = 200
    private let maxTextHeight: CGFloat = 4 * 40
    
    // Publisher to observe keyboard height changes
    private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .map { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0 },
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
        )
        .eraseToAnyPublisher()
    }
    
    var body: some View {
        ZStack {
            Color.black
            
            VStack {
                Spacer(minLength: 0)
                
                if isTextFieldVisible {
                    VStack(spacing: 0) {
                        GeometryReader { geometry in
                            VStack(spacing: 0) {
                                HStack(alignment: .center, spacing: 10) {
                                    // Clear button
                                    VStack {
                                        Spacer()
                                        Button(action: clearTextField) {
                                            Image("close")
                                                .resizable()
                                                .frame(width: buttonSize, height: buttonSize)
                                        }
                                        .padding(.bottom, 10)
                                    }
                                    .padding(.leading, -10)
                                    
                                    // Text input field
                                    ZStack {
                                        if text.isEmpty {
                                            Text("")
                                                .foregroundColor(.gray)
                                                .padding(.horizontal, 16)
                                                .font(.custom("ABCGravity-XXCompressed", size: fontSize))
                                                .multilineTextAlignment(.center)
                                                .frame(maxWidth: .infinity, alignment: .center)
                                                .textCase(.uppercase)
                                        }
                                        
                                        CustomTextEditor(text: $text, textHeight: $textHeight, fontSize: $fontSize, characterLimit: characterLimit, maxTextHeight: maxTextHeight)
                                            .focused($isFocused)
                                            .frame(height: min(textHeight, maxTextHeight))
                                            .background(Color.clear)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 5)
                                            .cornerRadius(45)
                                            .multilineTextAlignment(.center)
                                            .onChange(of: text) { _ in
                                                text = text.uppercased()
                                            }
                                    }
                                    .padding(.horizontal, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 45)
                                            .fill(Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 45)
                                                    .stroke(Color.white, lineWidth: 0.5)
                                            )
                                    )
                                    .frame(maxWidth: geometry.size.width - 80)
                                    
                                    // Send button
                                    VStack {
                                        Spacer()
                                        Button(action: sendMessage) {
                                            Image("send")
                                                .resizable()
                                                .frame(width: buttonSize, height: buttonSize)
                                        }
                                        .padding(.bottom, 10)
                                    }
                                    .padding(.trailing, -10)
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                                .background(Color.clear)
                            }
                            .padding(.horizontal, 10)
                            .padding(.top, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 45)
                                    .fill(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 45)
                                            .stroke(Color.clear, lineWidth: 0.5)
                                    )
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .frame(height: min(textHeight, maxTextHeight))
                    }
                    .padding(.bottom, keyboardHeight + 45)
                    .background(CustomRoundedShape(cornerRadius: 48).fill(Color.black.opacity(0.7)))
                    .overlay(
                        CustomRoundedShape(cornerRadius: 48)
                            .stroke(Color.white, lineWidth: 0.5)
                    )
                    .padding(.horizontal, 10)
                } else {
                    // Button to toggle the text field visibility
                    VStack {
                        Spacer()
                        HStack {
                            Button(action: toggleTextField) {
                                Image(systemName: "textformat")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18))
                                    .frame(width: buttonSize, height: buttonSize)
                                    .background(Circle().stroke(Color.white, lineWidth: 0.5))
                            }
                            .padding(.bottom, 10)
                            .transition(.scale(scale: 0.1, anchor: .bottomTrailing).combined(with: .opacity))
                            .padding(.leading, -10)
                            Spacer()
                        }
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onTapGesture { isFocused = false }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isFocused = true }
            observeKeyboardHeight()
        }
        .onDisappear {
            cancellable?.cancel()
        }
    }
    
    private func observeKeyboardHeight() {
        cancellable = keyboardPublisher
            .receive(on: RunLoop.main)
            .sink { height in
                self.keyboardHeight = height
            }
    }
    
    private func toggleTextField() {
        withAnimation(.easeInOut) {
            isTextFieldVisible.toggle()
            if isTextFieldVisible {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            } else {
                UIApplication.shared.endEditing()
            }
        }
    }
    
    private func clearTextField() {
        text = ""
        textHeight = 40
        isFocused = true
    }
    
    private func sendMessage() {
        print("Message sent: \(text)")
        text = ""
        textHeight = 40
    }
}

struct CustomTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var textHeight: CGFloat
    @Binding var fontSize: CGFloat
    let characterLimit: Int
    let maxTextHeight: CGFloat

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.showsVerticalScrollIndicator = false
        textView.backgroundColor = .clear
        textView.font = UIFont(name: "ABCGravity-XXCompressed", size: fontSize)
        textView.textColor = UIColor.white
        textView.delegate = context.coordinator
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textAlignment = .center
        textView.keyboardAppearance = .dark
        textView.autocorrectionType = .no
        textView.smartInsertDeleteType = .no
        textView.autocapitalizationType = .allCharacters
        textView.spellCheckingType = .no
        textView.tintColor = UIColor.white
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text.uppercased()
        }
        if uiView.font?.pointSize != fontSize {
            uiView.font = UIFont(name: "ABCGravity-XXCompressed", size: fontSize)
        }
        if let parent = uiView.superview, uiView.constraints.isEmpty {
            NSLayoutConstraint.activate([uiView.widthAnchor.constraint(equalTo: parent.widthAnchor, constant: -40)])
        }
        UITextView.adjustHeightToFit(uiView: uiView, height: $textHeight)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, characterLimit: characterLimit)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextEditor
        let characterLimit: Int

        init(_ parent: CustomTextEditor, characterLimit: Int) {
            self.parent = parent
            self.characterLimit = characterLimit
        }

        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async {
                if textView.text.count > self.characterLimit {
                    textView.text = String(textView.text.prefix(self.characterLimit))
                }
                self.parent.text = textView.text.uppercased() // Ensure text is always uppercase
                UITextView.adjustHeightToFit(uiView: textView, height: self.parent.$textHeight)
            }
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Intercept the return key to prevent new lines
            if text == "\n" {
                return false
            }
            return true
        }
    }
}

extension UITextView {
    static func adjustHeightToFit(uiView: UITextView, height: Binding<CGFloat>) {
        let size = uiView.sizeThatFits(CGSize(width: uiView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        DispatchQueue.main.async {
            if abs(height.wrappedValue - size.height) > 1 { // Only update if there's a significant change
                height.wrappedValue = size.height
                print("Adjusted height: \(height.wrappedValue)")
            }
        }
    }
}

struct CustomRoundedShape: Shape {
    var cornerRadius: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        path.addArc(center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        return path
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
