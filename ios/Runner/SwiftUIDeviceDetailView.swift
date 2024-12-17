import SwiftUI

@objc class SwiftUIDeviceDetailView: NSObject {
    @objc func createWithFrame(_ frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> UIView {
        let data = args as? [String: Any] ?? [:]
        let controller = UIHostingController(rootView: DeviceDetailView(deviceDetails: data))
        controller.view.frame = frame
        return controller.view
    }
}

struct DeviceDetailView: View {
    let deviceDetails: [String: Any]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Device Details")
                .font(.title)
                .bold()

            ForEach(deviceDetails.keys.sorted(), id: \.self) { key in
                HStack {
                    Text("\(key):")
                        .fontWeight(.semibold)
                    Text("\(deviceDetails[key] ?? "N/A")")
                }
            }
        }
        .padding()
    }
}
