//
//  ContentView.swift
//  AprilTagLive
//

import SwiftUI

struct ContentView: View {
    @StateObject private var session = TagDetectionSession()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CameraPreviewView(session: session)
                .ignoresSafeArea()

            VStack {
                statusBanner
                Spacer()
                if let lastDetection = session.latestDetection {
                    detectionInfoCard(lastDetection)
                }
            }
            .padding()
        }
        .onAppear { session.start() }
        .onDisappear { session.stop() }
    }

    private var statusBanner: some View {
        let detected = session.latestDetection != nil
        return HStack(spacing: 8) {
            Image(systemName: detected ? "checkmark.circle.fill" : "viewfinder")
                .foregroundColor(detected ? .green : .white.opacity(0.6))
            Text(detected ? "Tag detected" : "Searching for tag…")
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.55))
        .cornerRadius(20)
    }

    private func detectionInfoCard(_ snapshot: TagDetectionSession.DetectionSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tag id \(snapshot.id)")
                .font(.headline)
                .foregroundColor(.green)
            Text(String(format: "decision margin: %.1f", snapshot.decisionMargin))
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            if let pose = snapshot.pose {
                Text(String(format: "position: (%.2f, %.2f, %.2f) m",
                            pose.translation[0], pose.translation[1], pose.translation[2]))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(String(format: "reproj error: %.3f", pose.reprojectionError))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding()
        .background(Color.black.opacity(0.55))
        .cornerRadius(10)
    }
}
