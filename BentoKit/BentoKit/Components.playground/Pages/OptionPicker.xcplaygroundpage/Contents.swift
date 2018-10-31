import UIKit
import Bento
import BentoKit
import BentoKitPlaygroundSupport
import PlaygroundSupport
import StyleSheets

extension String: Option {
    public var displayName: String {
        return self
    }
}

let component = Component.OptionPicker(
    options: [
        "🇬🇧",
        "🇺🇦",
        "🇷🇺",
        "🇵🇹",
        "🇸🇪",
        "🇵🇱",
    ],
    selected: "🇺🇦",
    didPickItem: {
        print("didPickItem", $0)
    }
)

PlaygroundPage.current.liveView = renderInTableView(component: component)

