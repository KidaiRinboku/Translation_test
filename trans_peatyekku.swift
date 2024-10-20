import SwiftUI
import Translation

class ViewModel: ObservableObject {
    @Published var foodItems: [String] = ["apple", "banana", "carrot","cola"]
    let initFoodItems: [String] = ["apple", "banana", "carrot","cola"]
    @Published var isTranslationSupported: Bool = true //言語ペアサポート状況
    
    func reset() {
        foodItems = initFoodItems  //初期値にリセット
    }
    
    func translateAllAtOnce(using session: TranslationSession) async {
        Task { @MainActor in
            let requests: [TranslationSession.Request] = foodItems.enumerated().map { (index, string) in
                    .init(sourceText: string, clientIdentifier: "\(index)")
            }
            do {
                for try await response in session.translate(batch: requests) {
                    guard let index = Int(response.clientIdentifier ?? "") else { continue }
                    foodItems[index] = response.targetText
                    print(response.targetText)
                }
            } catch {
                //エラーハンドリング
            }
        }
    }
    @MainActor
    func checkLanguageSupport(from source: Locale.Language, to target: Locale.Language) async {
        let availability = LanguageAvailability()
        let status = await availability.status(from: source, to: target)
        
        switch status {
        case .installed, .supported:
            isTranslationSupported = true
        case .unsupported:
            isTranslationSupported = false
        @unknown default:
            isTranslationSupported = false
            print("Not supported")
        }
    }
    
}

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var configuration: TranslationSession.Configuration?
    @State private var showAlert = false  //アラート表示用の状態
    
    //翻訳元と翻訳先の言語を定義
    let sourceLanguage = Locale.Language(identifier: "en-GB")
    let targetLanguage = Locale.Language(identifier: "en-US")
    
    
    var body: some View {
        VStack {
            ForEach(viewModel.foodItems, id: \.self) { item in
                Text(item)
                    .padding()
            }
            HStack {
                Button("Translate") {
                    Task {
                        await checkAndTriggerTranslation()
                    }
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
        //アラートの追加
        .alert("無理な言語ペアっす", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(sourceLanguage.languageCode?.identifier ?? "")-\(sourceLanguage.region?.identifier ?? "") ⇨ \(targetLanguage.languageCode?.identifier ?? "")-\(targetLanguage.region?.identifier ?? "")")
        }
        .padding()
        .navigationTitle("Batch all at once")
    }
    
    //翻訳を開始する前に言語サポートをチェックする関数
    private func checkAndTriggerTranslation() async {
        await viewModel.checkLanguageSupport(from: sourceLanguage, to: targetLanguage)
        if viewModel.isTranslationSupported {
            triggerTranslation()
        } else {
            // アラートを表示
            showAlert = true
        }
    }
    
    private func triggerTranslation() {
        if !viewModel.isTranslationSupported {
            return  //翻訳を開始しない
        }
        if configuration == nil {
            configuration = .init(source: sourceLanguage,
                                  target: targetLanguage)
        } else {
            configuration?.invalidate()
        }
    }
}
#Preview {
    ContentView()
}
