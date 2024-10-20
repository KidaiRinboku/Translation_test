import SwiftUI
import Translation

struct ContentView: View {
    @State private var sourceText = "Hello, world!"
    @State private var targetText = ""
    @State private var configuration: TranslationSession.Configuration?
    
    var body: some View {
        VStack {
                    TextField("Enter text to translate", text: $sourceText)
                        .textFieldStyle(.roundedBorder)
                    Button("Translate") {
                        triggerTranslation()
                    }
                    Text(verbatim: targetText)
                }
                .translationTask(configuration) { session in
                    do {
                        let response = try await session.translate(sourceText)
                        targetText = response.targetText
                    } catch {

                    }
                }
                .padding()
                .navigationTitle("Single string")
            }
            private func triggerTranslation() {
                guard configuration == nil else {
                    configuration?.invalidate()
                    return
                }
                configuration = .init(source: Locale.Language(identifier: "en"),
                                       target: Locale.Language(identifier: "ja"))
            }
        }
#Preview {
    ContentView()
}
