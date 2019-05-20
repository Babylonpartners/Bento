import UIKit

final class CollectionViewContainerCell: UICollectionViewCell {
    var containedView: UIView? {
        didSet {
            containedViewDidChange(from: oldValue, to: containedView)
        }
    }

    var component: AnyRenderable?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func responds(to aSelector: Selector!) -> Bool {
        guard let component = component?.cast(to: MenuItemsResponding.self) else {
            return super.responds(to: aSelector)
        }

        return component.responds(to: aSelector) || super.responds(to: aSelector)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        guard let component = component?.cast(to: MenuItemsResponding.self) else {
            return super.forwardingTarget(for: aSelector)
        }

        return component
    }
}

extension CollectionViewContainerCell: BentoReusableView {}
