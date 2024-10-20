import SwiftUI
import Translation

class ViewModel: ObservableObject {
    @Published var foodItems: [String] = ["apple", "banana", "carrot","cola"]  //デフォルト
    let initFoodItems: [String] = ["apple", "banana", "carrot","cola"] //初期化

    func reset() {
        foodItems = initFoodItems  //初期値にリセット
    }

    func translateAllAtOnce(using session: TranslationSession) async {
        Task { @MainActor in
            let requests: [TranslationSession.Request] = foodItems.map {
                TranslationSession.Request(sourceText: $0)
            }

            do {
                let responses = try await session.translations(from: requests)
                foodItems = responses.map {
                    $0.targetText
                }
            } catch {
                //エラーハンドリング
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        VStack {
            ForEach(viewModel.foodItems, id: \.self) { item in
                Text(item)
                    .padding()
            }
            HStack {
                Button("Translate") {
                    triggerTranslation()
                }
                Button("Reset") {
                    viewModel.reset()
                }
            }
        }
        .translationTask(configuration) { session in
            await viewModel.translateAllAtOnce(using: session)
        }
        .onAppear {
            viewModel.reset()
        }
        .padding()
        .navigationTitle("Batch all at once")
    }

    private func triggerTranslation() {
        if configuration == nil {
            configuration = .init(source: Locale.Language(identifier: "en"),
                                  target: Locale.Language(identifier: "ja"))
        } else {
            configuration?.invalidate()
        }
    }
}
#Preview {
    ContentView()
}
