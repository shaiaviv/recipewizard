import UIKit
import SwiftUI
import UniformTypeIdentifiers
import MobileCoreServices

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        extractURL { [weak self] urlString in
            guard let self else { return }
            DispatchQueue.main.async {
                let shareView = ShareView(urlString: urlString) {
                    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                }
                let host = UIHostingController(rootView: shareView)
                self.addChild(host)
                self.view.addSubview(host.view)
                host.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    host.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                    host.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                    host.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    host.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                ])
                host.didMove(toParent: self)
            }
        }
    }

    // MARK: - URL Extraction

    private func extractURL(completion: @escaping (String?) -> Void) {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem else {
            completion(nil)
            return
        }

        let providers = item.attachments ?? []

        // Try URL type first (most reliable)
        if let urlProvider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier) { data, _ in
                if let url = data as? URL {
                    completion(url.absoluteString)
                } else {
                    completion(nil)
                }
            }
            return
        }

        // Fallback: plain text — TikTok shares as "Check out this video! https://vm.tiktok.com/..."
        if let textProvider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            textProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { data, _ in
                let text = data as? String ?? ""
                // Extract first URL from the text
                let urlString = self.extractURLFromText(text)
                completion(urlString)
            }
            return
        }

        completion(nil)
    }

    private func extractURLFromText(_ text: String) -> String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.first.flatMap { $0.url?.absoluteString }
    }
}
