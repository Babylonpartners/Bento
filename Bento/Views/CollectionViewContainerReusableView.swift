import UIKit

final class CollectionViewContainerReusableView: UICollectionReusableView {
    var containedView: UIView? {
        didSet {
            containerViewDidChange(from: oldValue, to: containedView)
        }
    }

    var contentView: UIView {
        return self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CollectionViewContainerReusableView: BentoReusableView {}
