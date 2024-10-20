import SwiftUI
import Translation

struct ContentView: View {
    @State private var configuration = TranslationSession.Configuration(
        source: Locale.Language(identifier: "ja"),
        target: Locale.Language(identifier: "pt")
    )
    @State private var shouldDownload = false
    @State private var showAlreadyDownloadedAlert = false
    @State private var showDownloadCompleteAlert = false
    @State private var showUnsupportedAlert = false

    var body: some View {
        VStack(spacing: 20) {
            
            
            
            Text("これは、翻訳に必要な言語のDLをユーザに促すボタンだよ。")
            Button("必要言語をダウンロード") {
                Task {
                    await checkLanguageAvailability()
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundStyle(Color.white)
        }
        .translationTask(configuration) { session in
            if shouldDownload {
                do {
                    try await session.prepareTranslation()
                    await MainActor.run {
                        shouldDownload = false
                        showDownloadCompleteAlert = true
                    }
                } catch {

                }
            }
        }
        .alert("ダウンロード済みです", isPresented: $showAlreadyDownloadedAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("選択された言語ペアはサポートされていないか、無効です", isPresented: $showUnsupportedAlert) {
            Button("OK", role: .cancel) { }
        }
        .padding()
    }

    func checkLanguageAvailability() async {
        guard let sourceLanguage = configuration.source, let targetLanguage = configuration.target else {
            //source または target が nil の場合の処理
            await MainActor.run {
                showUnsupportedAlert = true
            }
            return
        }

        let availability = LanguageAvailability()
        let status = await availability.status(from: sourceLanguage, to: targetLanguage)
        switch status {
        case .installed:
            //言語が既にダウンロードされている場合
            await MainActor.run {
                showAlreadyDownloadedAlert = true
            }
        case .supported:
            //言語がサポートされており、ダウンロードが必要な場合
            await MainActor.run {
                shouldDownload = true
                configuration.invalidate()  //`translationTask` をトリガー
            }
        case .unsupported:
            //言語ペアがサポートされていない場合
            await MainActor.run {
                showUnsupportedAlert = true
            }
        @unknown default:
            //予期しないケースに対処
            await MainActor.run {
                showUnsupportedAlert = true
            }
        }
    }
}

#Preview {
    ContentView()
}
