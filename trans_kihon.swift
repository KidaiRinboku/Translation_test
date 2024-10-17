import SwiftUI
import Translation

struct ContentView: View {
    //翻訳機能の立ち上げを管理するフラグ
    @State private var showTranslation = false
    //翻訳元のテキスト
    var originalText = "Hallo, Welt!"
    
    
    
    var body: some View {
        VStack {
            //テキスト表示
            Text(verbatim: originalText)
            //翻訳機能立ち上げのフラグを切り替えるボタン
            Button("Translate") {
                showTranslation.toggle()
            }
        }.translationPresentation(isPresented: $showTranslation,
                                  text: originalText)
         .navigationTitle("Translate")
    }
}
#Preview {
    ContentView()
}
