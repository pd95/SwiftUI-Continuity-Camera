//
//  ContentView.swift
//  ContinuityCamera
//
//  Created by Philipp on 21.04.21.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View, DropDelegate {
    
    @State private var image: NSImage?
    @State private var hovering = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Drag a document here")
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8.0)
                            .strokeBorder(style: StrokeStyle(lineWidth: hovering ? 3 : 1))
                    )

                MyResponder(image: $image)
                    .frame(width: 100, alignment: .center)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8.0)
                            .stroke()
                    )
            }
            .frame(maxHeight: 50, alignment: .center)

            Divider()

            if let image = self.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $hovering, perform: { (itemProviders, targetPosition) -> Bool in
            let urlIdentifier = UTType.fileURL.identifier
            for itemProvider in itemProviders {
                if itemProvider.hasItemConformingToTypeIdentifier(urlIdentifier) {
                    print(itemProvider.loadItem(forTypeIdentifier: urlIdentifier, options: nil, completionHandler: { (item, error) in
                        if let error = error {
                            print(error)
                        }
                        if let item = item,
                           let data = item as? Data,
                           let url = URL(dataRepresentation: data, relativeTo: nil)
                        {
                            print(url)
                            if let nsImage = NSImage(contentsOf: url) {
                                DispatchQueue.main.async {
                                    self.image = nsImage
                                }
                            }
                        }
                    }))
                    return true
                }
            }
            return false
        })
        .frame(minWidth: 500, minHeight: 500)
        .padding()
    }

    func performDrop(info: DropInfo) -> Bool {
        print("performDrop: \(info)")
        if info.hasItemsConforming(to: [.image]) {
            
            return true
        }
        return false
    }
    
}

struct MyResponder: NSViewControllerRepresentable {
    
    @Binding var image: NSImage?

    typealias NSViewControllerType = MyViewController
    
    func makeNSViewController(context: Context) -> MyViewController {
        let vc = MyViewController(context.coordinator)
        return vc
    }
    
    func updateNSViewController(_ nsViewController: MyViewController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, NSServicesMenuRequestor {
        var parent: MyResponder

        init(_ parent: MyResponder) {
            self.parent = parent
        }
        
        func readSelection(from pasteboard: NSPasteboard) -> Bool {
            // Verify that the pasteboard contains image data.
            guard pasteboard.canReadItem(withDataConformingToTypes: NSImage.imageTypes) else {
                return false
            }
            // Load the image.
            guard let image = NSImage(pasteboard: pasteboard) else {
                return false
            }
            parent.image = image

            return true
        }
    }
    
    class MyViewController: NSViewController, NSTextViewDelegate {
        
        private let coordinator: Coordinator
        private lazy var contentView = NSTextView()

        override func loadView() {
            print("loadView")
            contentView.string = "Right click here"
            contentView.setContentHuggingPriority(.defaultHigh, for: .vertical)
            contentView.setContentHuggingPriority(.defaultLow, for: .horizontal)
            contentView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            contentView.delegate = self
            view = contentView
        }
        
        init(_ coordinator: Coordinator) {
            self.coordinator = coordinator
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError()
        }
        
        func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
            return NSMenu(title: menu.title)
        }
        
        override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
            if let pasteboardType = returnType,
                // Service is image related.
                NSImage.imageTypes.contains(pasteboardType.rawValue) {
                return coordinator  // This object can receive image data.
            } else {
                // Let objects in the responder chain handle the message.
                return super.validRequestor(forSendType: sendType, returnType: returnType)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
