import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationStack {
            TabView {
                GameView()
            }
            .navigationTitle("Sound Check")

        }
    }

}

#Preview {
    ContentView()
}
