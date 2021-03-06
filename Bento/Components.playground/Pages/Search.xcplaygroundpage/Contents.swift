import UIKit
import Bento
import BentoPlaygroundSupport
import PlaygroundSupport

let bundle = Bundle(for: Component.TextInput.self)
let styleSheet = Component.Search.StyleSheet()
    .compose(\.searchBar.textInputBackgroundColor, UIColor.gray.withAlphaComponent(0.25))
let component = Component.Search(
    placeholder: "Placeholder",
    keyboardType: .default,
    didBeginEditing: { _ in
        print("didBeginEditing")
},
    textDidChange: { _, text in
        print("textDidChange", text)
},
    showsCancelButton: true,
    cancelButtonClicked: {
        print("cancelButtonClicked")
        $0.endEditing(true)
},
    styleSheet: styleSheet
)

PlaygroundPage.current.liveView = renderInTableView(component: component)
