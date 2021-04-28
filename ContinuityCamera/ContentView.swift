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
    @State private var icon: NSImage?
    @State private var fileType: UTType?
    @State private var fileName: String?
    @State private var message: String?
    @State private var hovering = false
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    icon.map(Image.init)
                    fileName.map(Text.init)
                }
                message.map(Text.init)
            }
            HStack {
                Text("Drag a document here")
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8.0)
                            .strokeBorder(style: StrokeStyle(lineWidth: hovering ? 3 : 1))
                    )

                Text("or right click here")
                    .allowsHitTesting(false)
                    .padding()
                    .background(
                        ContinuityCameraStartView(placeholder: "") { data, fileType in
                            print("ContinuityCamera is sending \(fileType): \(data)")
                            self.showImage(data: data, fileType: fileType)
                            return true
                        }
                    )
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
                    .background(Color.white)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $hovering, perform: { (itemProviders, targetPosition) -> Bool in
            let urlIdentifier = UTType.fileURL.identifier
            for itemProvider in itemProviders {
                if itemProvider.hasItemConformingToTypeIdentifier(urlIdentifier) {
                    itemProvider.loadItem(forTypeIdentifier: urlIdentifier, options: nil, completionHandler: { (item, error) in
                        if let error = error {
                            print(error)
                        }
                        if let item = item,
                           let data = item as? Data,
                           let url = URL(dataRepresentation: data, relativeTo: nil),
                           let data = try? Data(contentsOf: url),
                           let fileType = UTType(filenameExtension: url.pathExtension)
                        {
                            self.showImage(data: data, fileType: fileType, fileName: url.lastPathComponent)
                        }
                        else {
                            print("Something is wrong with the data: \(String(describing: item))")
                        }
                    })
                    return true
                }
            }
            return false
        })
        .frame(minWidth: 500, minHeight: 500)
        .padding()
    }
    
    private func showImage(data: Data, fileType: UTType, fileName: String = "No Name") {
        let nsImage = NSImage(data: data)
        DispatchQueue.main.async {
            self.image = nsImage
            self.fileType = fileType
            self.icon = NSWorkspace.shared.icon(for: fileType)
            self.fileName = fileName
            self.message = nsImage == nil ? "Not a valid image" : nil
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        print("performDrop: \(info)")
        if info.hasItemsConforming(to: [.image]) {
            
            return true
        }
        return false
    }
}

struct ContinuityCameraStartView: NSViewRepresentable {
    
    let placeholder: String
    let handler: (Data, UTType) -> Bool

    typealias NSViewType = MyTextView
    
    func makeNSView(context: Context) -> MyTextView {
        let view = MyTextView()
        view.string = placeholder
        view.drawsBackground = false
        view.insertionPointColor = NSColor.textBackgroundColor
        view.autoresizingMask = [.width, .height]
        view.delegate = context.coordinator

        return view
    }
    
    func updateNSView(_ nsViewController: MyTextView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate, NSServicesMenuRequestor {
        var parent: ContinuityCameraStartView

        init(_ parent: ContinuityCameraStartView) {
            self.parent = parent
            super.init()
        }
        
        required init?(coder: NSCoder) {
            fatalError()
        }
        
        func readSelection(from pasteboard: NSPasteboard) -> Bool {
            // Verify that the pasteboard contains image data.
            guard pasteboard.canReadItem(withDataConformingToTypes: NSImage.imageTypes) else {
                return false
            }

            let validImageTypes = Set(NSImage.imageTypes)
            let availableTypes = (pasteboard.types ?? []).map(\.rawValue)
            let availableImageTypes = validImageTypes.intersection(availableTypes)

            // If multiple formats are available, try looking for jpeg first
            let jpegIdentifier = UTType.jpeg.identifier
            if availableImageTypes.contains(jpegIdentifier) {
                if let data = pasteboard.data(forType: NSPasteboard.PasteboardType(jpegIdentifier)) {
                    if parent.handler(data, .jpeg) {
                        return true
                    }
                }
            }
            
            var result = false
            availableTypes.forEach { type in
                if !result,
                   let utType = UTType(type),
                   let data = pasteboard.data(forType: NSPasteboard.PasteboardType(type))
                {
                    if parent.handler(data, utType) {
                        result = true
                    }
                }
            }

            return result
        }

        func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
            // Return an empty context menu
            return NSMenu(title: menu.title)
        }

        func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
            // Ignore user selection
            NSMakeRange(0, 0)
        }
    }

    final class MyTextView: NSTextView {
        override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
            if let pasteboardType = returnType,
                // Service is image related.
                NSImage.imageTypes.contains(pasteboardType.rawValue) {
                return self.delegate
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
