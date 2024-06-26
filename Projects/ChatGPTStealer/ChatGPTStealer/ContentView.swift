//
//  ContentView.swift
//  ChatGPTStealer
//
//  Created by Pedro José Pereira Vieito on 26/6/24.
//

import SwiftUI

struct ContentView: View {
    struct Message: Identifiable {
        let id: UUID
        let author: String
        let content: String
        let createdAt: Date
    }

    @State private var conversation: [Message] = []
    
    var body: some View {
        VStack {
            Spacer()
            Button("Load Chat…") {
                self.loadLatestConversation()
            }
            Divider()
            List(conversation) { message in
                VStack(alignment: .leading) {
                    Text(message.author)
                        .font(.headline)
                    Text(message.content)
                        .font(.body)
                }
            }
        }
    }
    
    func loadLatestConversation() {
        guard let url = getLastModifiedFileURL() else { return }
        if let plistData = try? Data(contentsOf: url),
           let plistDict = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
           let treeDict = plistDict["tree"] as? [String: Any],
           let storageDict = treeDict["storage"] as? [String: Any] {
            
            var messages: [Message] = []
            for (_, node) in storageDict {
                if let nodeDict = node as? [String: Any],
                   let contentDict = nodeDict["content"] as? [String: Any],
                   let authorDict = contentDict["author"] as? [String: Any],
                   let author = authorDict["role"] as? String,
                   let contentParts = contentDict["content"] as? [String: Any],
                   let parts = contentParts["parts"] as? [String],
                   let content = parts.first,
                   let createdAt = nodeDict["createdAt"] as? Date {
                    let message = Message(id: UUID(), author: author, content: content, createdAt: createdAt)
                    messages.append(message)
                }
            }
            
            self.conversation = messages.sorted(by: { $0.createdAt < $1.createdAt })
        }
    }
    
    func getLastModifiedFileURL() -> URL? {
        let fileManager = FileManager.default
        let directoryURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.openai.chat", isDirectory: true)
        
        guard let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else { return nil }
        
        var latestFileURL: URL?
        var latestModificationDate: Date?
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "data" {
                let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path)
                let modificationDate = attributes?[.modificationDate] as? Date
                if let modificationDate = modificationDate {
                    if latestModificationDate == nil || modificationDate > latestModificationDate! {
                        latestModificationDate = modificationDate
                        latestFileURL = fileURL
                    }
                }
            }
        }
        
        return latestFileURL
    }
}

#Preview {
    ContentView()
}
