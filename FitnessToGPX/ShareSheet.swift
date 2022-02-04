//
//  ShareSheet.swift
//  FitnessToGPX
//
//  Created by Sergej Jaskiewicz on 03.02.2022.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {

    let activityItems: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems,
                                                  applicationActivities: nil)
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController,
                                context: Context) {
        // nothing to do here
    }
}
