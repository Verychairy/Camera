import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        CameraViewControllerRepresentable()
            .ignoresSafeArea()
    }
}

struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
    }
}