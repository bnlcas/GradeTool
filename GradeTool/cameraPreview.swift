//
//  cameraPreview.swift
//  GradeTool
//
//  Created by Benjamin Lucas on 9/6/24.
//

import SwiftUI
import AVFoundation
struct cameraPreview: View {
    let captureSession = AVCaptureSession()
    var videoOutput: AVCaptureMovieFileOutput!
    
    
    public func configure() {
        // Preset the session for taking photo in full resolution
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        // Get the front and back-facing camera for taking photos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        var currentDevice: AVCaptureDevice

        for device in deviceDiscoverySession.devices {
            if device.position == .back {
                currentDevice = device
            }
        }
        
        /*
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: currentDevice) else {
            return
        }
        
        captureSession.addInput(captureDeviceInput)

        // Configure the session with the output for capturing still images
        //stillImageOutput = AVCapturePhotoOutput()
        
        // Configure the session with the input and the output devices
        captureSession.addOutput(videoOutput)
        
        captureSession.startRunning()
         */
    }
    
    init()
    {
        //configure()
    }
    
    var body: some View {
        Image(systemName: "triangle")
        //AVCaptureVi
        //AVCaptureVideoPreviewLayer(session: captureSession)
    }
}

#Preview {
    cameraPreview()
}
