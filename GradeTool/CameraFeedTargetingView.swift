//
//  CameraFeedTargetingView.swift
//  GradeTool
//
//  Created by Benjamin Lucas on 4/5/25.
//

import SwiftUI
import AVFoundation

struct CameraFeedTargetingView: View {
    @State private var zoomFactor: CGFloat = 1.5  // initial zoom factor
    @State private var lastZoomFactor: CGFloat = 1.5

    var body: some View {
        GeometryReader { geometry in
            // Use the smallest dimension to form a square.
            let side = min(geometry.size.width, geometry.size.height)
            CameraPreviewView(zoomFactor: $zoomFactor)
                .frame(width: side, height: side, alignment: .center)
                .clipped() // crop any overflow
                //.cornerRadius(8)
                .clipShape(Rectangle())
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            // Multiply the starting zoom factor by the magnification amount.
                            let newZoom = lastZoomFactor * value
                            // Clamp between 1.0 and 5.0 (or you can query the device’s maximum).
                            zoomFactor = min(max(newZoom, 1.0), 5.0)
                        }
                        .onEnded { _ in
                            lastZoomFactor = zoomFactor
                        }
                )
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    @Binding var zoomFactor: CGFloat

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        DispatchQueue.main.async {
            view.setupSession()
        }
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.updateZoom(factor: zoomFactor)
    }
}

class CameraPreviewUIView: UIView {
    var session: AVCaptureSession?

    // Tell the view to use an AVCaptureVideoPreviewLayer as its backing layer.
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    // Convenience accessor for the layer as an AVCaptureVideoPreviewLayer.
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    func setupSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .medium// .high

        // Get the back, built-in wide-angle camera.
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back) else {
            print("No back camera available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Error creating camera input: \(error)")
            return
        }

        // Configure the preview layer.
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill  // fill view and crop excess
        session.startRunning()
        self.session = session
    }

    func updateZoom(factor: CGFloat) {
        // Access the camera device.
        guard let device = (session?.inputs.first as? AVCaptureDeviceInput)?.device else { return }
        do {
            try device.lockForConfiguration()
            // Clamp the zoom factor between 1.0 and device.maxZoom (or a fixed value, here 5.0).
            let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 5.0)
            let newZoom = min(max(factor, 1.0), maxZoom)
            device.videoZoomFactor = newZoom
            device.unlockForConfiguration()
        } catch {
            print("Error setting zoom: \(error)")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        if let connection = previewLayer.connection, connection.isVideoRotationAngleSupported(90.0) {
            connection.videoRotationAngle = 90.0
        }
        
        // Assume the camera feed is 4:3.
        // When filling a square view (width == height), the scaled height is:
        let cameraAspectRatio: CGFloat = 1.0// 4.0 / 3.0
        let scaledHeight = bounds.width * cameraAspectRatio
        // Calculate how much extra height exists and shift upward by half that.
        let verticalOverflow = scaledHeight - bounds.height
        let yOffset = verticalOverflow / 2.0
        
        // Apply a translation transform to the preview layer to shift it upward.
        previewLayer.setAffineTransform(CGAffineTransform(translationX: 0, y: -yOffset))
    }
}

