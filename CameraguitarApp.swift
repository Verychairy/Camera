import SwiftUI

@main
struct CameraguitarApp: App {
    var body: some Scene {
        WindowGroup {
            CameraViewControllerRepresentable() // Use the wrapper to display CameraViewController
        }
    }
}
