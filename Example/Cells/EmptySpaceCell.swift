import UIKit
import Bento

final class EmptySpaceCell: UIView, NibLoadable {
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
}

final class EmptySpaceComponent: Renderable {
    struct Spec {
        let height: CGFloat
        let color: UIColor
    }
    private let spec: Spec

    init(spec: Spec) {
        self.spec = spec
    }

    func render(in view: EmptySpaceCell) {
        let animation = CABasicAnimation(keyPath: "backgroundColor")
        animation.fromValue = view.layer.backgroundColor
        animation.toValue = spec.color.cgColor
        view.heightConstraint.constant = spec.height
        view.layer.add(animation, forKey: nil)
        view.layer.backgroundColor = spec.color.cgColor
    }
}
