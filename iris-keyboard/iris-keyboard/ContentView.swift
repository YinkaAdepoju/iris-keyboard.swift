import SwiftUI
import Combine

struct ContentView: View {
    @State private var text: String = ""
    @State private var textHeight: CGFloat = 40 // Initial height for the input field
    @State private var fontSize: CGFloat = 30 // Start with the maximum font size
    @FocusState private var isFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    @State private var cancellable: AnyCancellable?

    private var buttonSize: CGFloat = 44 // Define a consistent size for the buttons
    private let characterLimit = 100 // Character limit

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
            Color.black // Background color

            VStack {
                Spacer(minLength: 0) // Remove or minimize the spacer

                // Outer container with stroke and custom font
                VStack(spacing: 0) {
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            HStack(alignment: .center, spacing: 10) {
                                // Left button (close button)
                                VStack {
                                    Spacer()
                                    Button(action: {}) {
                                        Image(systemName: "xmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 18)) // Smaller size
                                            .frame(width: buttonSize, height: buttonSize)
                                            .background(Circle().stroke(Color.white, lineWidth: 0.5))
                                    }
                                    .padding(.bottom, 10) // Move button upwards
                                }
                                .padding(.leading, -10) // Decrease margin from the edge

                                // Text input field in pill shape with stroke
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

                                    CustomTextEditor(text: $text, textHeight: $textHeight, fontSize: $fontSize, characterLimit: characterLimit)
                                        .focused($isFocused)
                                        .frame(height: textHeight)
                                        .background(Color.clear)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 10) // Added padding to the top of the text input field
                                        .cornerRadius(45)
                                        .multilineTextAlignment(.center)
                                        .onChange(of: text) { _ in
                                            text = text.uppercased() // Transform text to uppercase
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

                                // Right button (send button)
                                VStack {
                                    Spacer()
                                    Button(action: { print(text) }) {
                                        Image(systemName: "paperplane.fill")
                                            .foregroundColor(.black) // Black paper plane
                                            .font(.system(size: 18))
                                            .frame(width: buttonSize, height: buttonSize)
                                            .background(Circle().fill(Color.white)) // White circle
                                    }
                                    .padding(.bottom, 10) // Move button upwards
                                }
                                .padding(.trailing, -10) // Decrease margin from the edge
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                            .background(Color.clear)
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 15) // Further reduced padding to move the outer box up
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
                    .frame(height: textHeight)
                }
                .padding(.bottom, keyboardHeight + 45) // Adjust padding for keyboard and bottom alignment
                .background(CustomRoundedShape(cornerRadius: 48).fill(Color.black.opacity(0.7)))
                .overlay(
                    CustomRoundedShape(cornerRadius: 48)
                        .stroke(Color.white, lineWidth: 0.5)
                )
                .padding(.horizontal, 10) // Reduce margin from outer edges
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
}

struct CustomTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var textHeight: CGFloat
    @Binding var fontSize: CGFloat
    let characterLimit: Int

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.font = UIFont(name: "ABCGravity-XXCompressed", size: fontSize)
        textView.textColor = UIColor.white
        textView.delegate = context.coordinator
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textAlignment = .center // Center the text input
        textView.keyboardAppearance = .dark // Force black keyboard
        textView.autocorrectionType = .no // Disable autocorrection (predictive text)
        textView.smartInsertDeleteType = .no // Disable smart insert/delete
        textView.autocapitalizationType = .allCharacters // Force all uppercase
        textView.spellCheckingType = .no // Disable spell checking
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text.uppercased() // Ensure text is always uppercase
        }
        if uiView.font?.pointSize != fontSize {
            uiView.font = UIFont(name: "ABCGravity-XXCompressed", size: fontSize)
        }
        if let parent = uiView.superview, uiView.constraints.isEmpty {
            NSLayoutConstraint.activate([uiView.widthAnchor.constraint(equalTo: parent.widthAnchor, constant: -40)])
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self, characterLimit: characterLimit) }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextEditor
        let characterLimit: Int

        init(_ parent: CustomTextEditor, characterLimit: Int) {
            self.parent = parent
            self.characterLimit = characterLimit
        }

        func textViewDidChange(_ textView: UITextView) {
            if textView.text.count > characterLimit {
                textView.text = String(textView.text.prefix(characterLimit))
            }
            parent.text = textView.text.uppercased() // Ensure text is always uppercase
            UITextView.adjustHeightToFit(uiView: textView, height: parent.$textHeight)
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    height.wrappedValue = size.height
                }
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
