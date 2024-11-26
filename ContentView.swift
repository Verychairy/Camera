import UIKit
import AVFoundation
import AVKit

class CameraViewController: UIViewController {
    
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var gridLayer: CAShapeLayer?
    private var audioPlayer: AVAudioPlayer?
    
    // Create an array for the sound files (using WAV files)
    let guitarSounds = [
        "sound1", "sound2", "sound3", "sound4",
        "sound5", "sound6", "sound7", "sound8",
        "sound9", "sound10", "sound11", "sound12"
    ]
    
    
    // Add properties for line vibration
    private var animatingLines: [CAShapeLayer] = []
    
    // Add properties for dynamic animation
    private var gridLines: [CAShapeLayer] = []
    private var displayLink: CADisplayLink?
    private var animationTime: CFTimeInterval = 0
    
    // Update to store line segments instead of full lines
    private var verticalSegments: [CAShapeLayer] = []
    private var horizontalSegments: [CAShapeLayer] = []
    
    // Store all lines in a single array
    private var allLines: [CAShapeLayer] = []
    
    // Add UI element properties
    private let topControlsView = UIView()
    private let bottomControlsView = UIView()
    
    // Add these new properties
    private let topBlackBar = UIView()
    private let bottomBlackBar = UIView()
    private let cameraView = UIView()
    
    private var lineSegments: [(start: CGPoint, end: CGPoint)] = []
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view controller to full screen
        modalPresentationStyle = .fullScreen
        
        // Initialize preview layer first
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        
        setupAudioSession()
        setupCamera()
        setupUI()
        addGridOverlay()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide status bar when view appears
        navigationController?.setNavigationBarHidden(true, animated: false)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = cameraView.bounds
        // Re-add grid overlay when view layout changes
        addGridOverlay()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("✅ Audio session setup successful")
        } catch {
            print("❌ Failed to set up audio session: \(error)")
        }
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get camera device")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // Add preview layer to view
            view.layer.addSublayer(previewLayer)
            
            // Start capture session on background thread
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    private func setupUI() {
        // Set the entire view hierarchy to black background
        view.backgroundColor = .black
        topBlackBar.backgroundColor = .black
        bottomBlackBar.backgroundColor = .black
        cameraView.backgroundColor = .black
        
        // Get device screen dimensions
        let screen = UIScreen.main.bounds
        let safeArea = view.safeAreaInsets
        
        // Adjust back to original values
        let topHeight: CGFloat = safeArea.top + 60  // Reduced from 90 to 60 to fix the ratio
        let bottomHeight: CGFloat = safeArea.bottom + 180
        
        // Add views in the correct order
        [cameraView, topBlackBar, bottomBlackBar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // Add preview layer to camera view
        previewLayer.frame = cameraView.bounds
        cameraView.layer.addSublayer(previewLayer)
        
        // Top overlay
        let topOverlay = UIImageView()
        topOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topOverlay)
        
        // Bottom overlay
        let bottomOverlay = UIImageView()
        bottomOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomOverlay)
        
        // Set the images (normal mode, not template)
        topOverlay.image = UIImage(named: "Iphone upper")
        bottomOverlay.image = UIImage(named: "Iphone below")
        
        // Set content mode
        topOverlay.contentMode = .scaleAspectFit
        bottomOverlay.contentMode = .scaleAspectFit
        
        NSLayoutConstraint.activate([
            // Camera view constraints
            cameraView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Black bars constraints
            topBlackBar.topAnchor.constraint(equalTo: view.topAnchor),
            topBlackBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBlackBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBlackBar.heightAnchor.constraint(equalToConstant: topHeight),
            
            // Top overlay constraints
            topOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            topOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topOverlay.heightAnchor.constraint(equalToConstant: topHeight),
            
            // Bottom overlay and black bar constraints
            bottomOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomOverlay.heightAnchor.constraint(equalToConstant: bottomHeight),
            
            bottomBlackBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBlackBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBlackBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBlackBar.heightAnchor.constraint(equalToConstant: bottomHeight)
        ])
    }
    
    private func addGridOverlay() {
        allLines.forEach { $0.removeFromSuperlayer() }
        allLines.removeAll()
        
        let width = view.bounds.width
        let safeArea = view.safeAreaInsets
        
        // Match the new top height for grid positioning
        let topHeight: CGFloat = safeArea.top + 60
        let bottomHeight: CGFloat = safeArea.bottom + 180
        
        // Calculate exact grid dimensions
        let availableHeight = view.bounds.height - topHeight - bottomHeight
        let cellWidth = floor(width / 3)  // Use floor to avoid rounding issues
        let cellHeight = floor(availableHeight / 3)  // Use floor to avoid rounding issues
        
        // Calculate starting Y position
        let gridStartY = topHeight
        let gridEndY = view.bounds.height - bottomHeight
        
        // Create vertical lines with exact same height
        for i in 1...2 {
            let x = CGFloat(i) * cellWidth
            let line = CAShapeLayer()
            let path = UIBezierPath()
            
            // Use exact same start and end points for all vertical lines
            path.move(to: CGPoint(x: x, y: gridStartY))
            path.addLine(to: CGPoint(x: x, y: gridEndY))
            
            line.path = path.cgPath
            line.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
            line.lineWidth = 0.5
            
            cameraView.layer.addSublayer(line)
            allLines.append(line)
        }
        
        // Create horizontal lines
        for i in 1...2 {
            let y = gridStartY + (CGFloat(i) * cellHeight)
            let line = CAShapeLayer()
            let path = UIBezierPath()
            
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
            
            line.path = path.cgPath
            line.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
            line.lineWidth = 0.5
            
            cameraView.layer.addSublayer(line)
            allLines.append(line)
        }
    }
    
    private func addCornerGuides() {
        let guideColor = UIColor.white.withAlphaComponent(0.4)
        let guideLength: CGFloat = 15
        let guideThickness: CGFloat = 0.5
        let _: CGFloat = 0  // No padding for exact corner placement
        
        let corners = [
            // Top-left
            (CGPoint(x: 0, y: 0),
             CGPoint(x: guideLength, y: 0),
             CGPoint(x: 0, y: guideLength)),
            
            // Top-right
            (CGPoint(x: cameraView.bounds.width, y: 0),
             CGPoint(x: cameraView.bounds.width - guideLength, y: 0),
             CGPoint(x: cameraView.bounds.width, y: guideLength)),
            
            // Bottom-left
            (CGPoint(x: 0, y: cameraView.bounds.height),
             CGPoint(x: guideLength, y: cameraView.bounds.height),
             CGPoint(x: 0, y: cameraView.bounds.height - guideLength)),
            
            // Bottom-right
            (CGPoint(x: cameraView.bounds.width, y: cameraView.bounds.height),
             CGPoint(x: cameraView.bounds.width - guideLength, y: cameraView.bounds.height),
             CGPoint(x: cameraView.bounds.width, y: cameraView.bounds.height - guideLength))
        ]
        
        corners.forEach { corner in
            let path = UIBezierPath()
            path.move(to: corner.0)
            path.addLine(to: corner.1)
            path.move(to: corner.0)
            path.addLine(to: corner.2)
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath
            shapeLayer.strokeColor = guideColor.cgColor
            shapeLayer.lineWidth = guideThickness
            cameraView.layer.addSublayer(shapeLayer)
        }
    }
    
    private func startDynamicAnimation() {
        // Stop existing animation if any
        displayLink?.invalidate()
        
        // Create new display link
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateAnimation() {
        animationTime += 0.01
        
        for (index, line) in gridLines.enumerated() {
            // Create different frequencies for each line
            let frequency = 2.0 + Double(index) * 0.5
            let amplitude = 1.5
            
            // Calculate offset based on sine wave
            let offset = CGFloat(sin(animationTime * frequency) * amplitude)
            
            // Apply different transform based on line orientation
            if index < 2 { // Vertical lines
                line.transform = CATransform3DMakeTranslation(offset, 0, 0)
            } else { // Horizontal lines
                line.transform = CATransform3DMakeTranslation(0, offset, 0)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        displayLink?.invalidate()
        displayLink = nil
    }
    
    // When touch occurs, increase vibration temporarily
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: view)
        
        let width = view.bounds.width
        let topHeight: CGFloat = 100
        let bottomHeight: CGFloat = 250
        let cameraHeight = view.bounds.height - topHeight - bottomHeight
        
        // Scale threshold based on screen width
        let touchThreshold: CGFloat = 30.0 * (width / 390)
        
        print("Touch location: x: \(location.x), y: \(location.y)")
        
        let lineSegments = [
            // Left vertical segments (top to bottom) - 0,1,2
            (start: CGPoint(x: width/3, y: topHeight - 30), 
             end: CGPoint(x: width/3, y: topHeight + cameraHeight/3 + 30)),
            (start: CGPoint(x: width/3, y: topHeight + cameraHeight/3), 
             end: CGPoint(x: width/3, y: topHeight + 2*cameraHeight/3)),
            (start: CGPoint(x: width/3, y: topHeight + 2*cameraHeight/3), 
             end: CGPoint(x: width/3, y: view.bounds.height - bottomHeight + 90)),
            
            // Right vertical segments (top to bottom) - 3,4,5
            (start: CGPoint(x: 2*width/3, y: topHeight), 
             end: CGPoint(x: 2*width/3, y: topHeight + cameraHeight/3)),
            (start: CGPoint(x: 2*width/3, y: topHeight + cameraHeight/3), 
             end: CGPoint(x: 2*width/3, y: topHeight + 2*cameraHeight/3)),
            (start: CGPoint(x: 2*width/3, y: topHeight + 2*cameraHeight/3), 
             end: CGPoint(x: 2*width/3, y: view.bounds.height - bottomHeight + 90)),
            
            // Horizontal segments (left to right) - 6,7,8
            (start: CGPoint(x: 0, y: topHeight + cameraHeight/3), 
             end: CGPoint(x: width/3, y: topHeight + cameraHeight/3)),
            (start: CGPoint(x: width/3, y: topHeight + cameraHeight/3), 
             end: CGPoint(x: 2*width/3, y: topHeight + cameraHeight/3)),
            (start: CGPoint(x: 2*width/3, y: topHeight + cameraHeight/3), 
             end: CGPoint(x: width, y: topHeight + cameraHeight/3)),
            
            // Bottom horizontal segments (left to right) - 9,10,11
            (start: CGPoint(x: 0, y: 425), 
             end: CGPoint(x: width/3, y: 425)),
            (start: CGPoint(x: width/3, y: 425), 
             end: CGPoint(x: 2*width/3, y: 425)),
            (start: CGPoint(x: 2*width/3, y: 425), 
             end: CGPoint(x: width, y: 425))
        ]
        
        var closestDistance = CGFloat.infinity
        var closestIndex = -1
        
        for (index, segment) in lineSegments.enumerated() {
            let distance = distanceFromPoint(location, toLineSegment: segment.start, segment.end)
            
            // For vertical lines (indices 0-5)
            if index <= 5 {
                if distance < touchThreshold &&
                   location.y >= segment.start.y &&
                   location.y <= segment.end.y {
                    if distance < closestDistance {
                        closestDistance = distance
                        closestIndex = index
                    }
                }
            }
            // For horizontal lines (indices 6-11)
            else {
                if distance < touchThreshold &&
                   location.x >= segment.start.x &&
                   location.x <= segment.end.x &&
                   abs(location.y - segment.start.y) < touchThreshold {
                    if distance < closestDistance {
                        closestDistance = distance
                        closestIndex = index
                    }
                }
            }
        }
        
        if closestIndex != -1 {
            print("Line segment touched: \(closestIndex)")
            playGuitarSound(forLine: closestIndex)
            
            if let line = allLines.first(where: { 
                distanceFromPoint(location, toPath: $0.path!) < touchThreshold 
            }) {
                animateLineTouch(line, isHorizontal: closestIndex >= 6)
            }
        }
    }
    
    private func animateLineTouch(_ line: CAShapeLayer, isHorizontal: Bool) {
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.duration = 0.3
        
        if isHorizontal {
            animation.values = [
                CGPoint(x: 0, y: -2),
                CGPoint(x: 0, y: 2),
                CGPoint(x: 0, y: -2),
                CGPoint(x: 0, y: 2),
                CGPoint(x: 0, y: 0)
            ].map { NSValue(cgPoint: $0) }
        } else {
            animation.values = [
                CGPoint(x: -2, y: 0),
                CGPoint(x: 2, y: 0),
                CGPoint(x: -2, y: 0),
                CGPoint(x: 2, y: 0),
                CGPoint(x: 0, y: 0)
            ].map { NSValue(cgPoint: $0) }
        }
        
        line.add(animation, forKey: "vibrate")
    }
    
    private func playGuitarSound(forLine index: Int) {
        print("Attempting to play sound for line: \(index)")
        guard index >= 0 && index < guitarSounds.count else {
            print("Invalid sound index: \(index)")
            return
        }
        
        let soundFileName = guitarSounds[index]
        if let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: "wav") {
            do {
                audioPlayer?.stop() // Stop any existing playback
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
                print("Playing sound: \(soundFileName)")
            } catch {
                print("Error playing sound: \(error)")
            }
        } else {
            print("Could not find sound file: \(soundFileName)")
        }
    }
    
    private func distanceFromPoint(_ point: CGPoint, toPath path: CGPath) -> CGFloat {
        var closestDistance = CGFloat.infinity
        var startPoint: CGPoint?
        
        path.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                startPoint = element.pointee.points[0]
            case .addLineToPoint:
                if let start = startPoint {
                    let end = element.pointee.points[0]
                    let distance = distanceFromPoint(point, toLineSegment: start, end)
                    closestDistance = min(closestDistance, distance)
                }
                startPoint = element.pointee.points[0]
            default:
                break
            }
        }
        
        return closestDistance
    }
    
    private func distanceFromPoint(_ point: CGPoint, toLineSegment start: CGPoint, _ end: CGPoint) -> CGFloat {
        let a = point.x - start.x
        let b = point.y - start.y
        let c = end.x - start.x
        let d = end.y - start.y
        
        let dot = a * c + b * d
        let lenSq = c * c + d * d
        
        var param: CGFloat = -1
        if lenSq != 0 {
            param = dot / lenSq
        }
        
        var nearestX: CGFloat
        var nearestY: CGFloat
        
        if param < 0 {
            nearestX = start.x
            nearestY = start.y
        } else if param > 1 {
            nearestX = end.x
            nearestY = end.y
        } else {
            nearestX = start.x + param * c
            nearestY = start.y + param * d
        }
        
        let dx = point.x - nearestX
        let dy = point.y - nearestY
        
        return sqrt(dx * dx + dy * dy)
    }
}

// Helper extension for creating circular paths
extension UIBezierPath {
    convenience init(circleIn rect: CGRect) {
        self.init(ovalIn: rect)
    }
}


// Add AVAudioPlayerDelegate
extension CameraViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print(flag ? "✅ Audio finished playing successfully" : "❌ Audio did not finish successfully")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("❌ Audio player decode error: \(error)")
        }
    }
}
