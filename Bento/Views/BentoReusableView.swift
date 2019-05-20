/// Protocol for reusable views (cell, header, footer) in `UITableView`, `UICollectionView`, etc.
protocol BentoReusableView: AnyObject {
    /// The view to which `containedView` should be added.
    /// - Note: This is normally system-provided as `self`'s subview.
    var contentView: UIView { get }

    /// The component root view that is currently added in `contentView`.
    /// If the existing view is no longer compatible with the newly set `component`,
    /// a new compatible view should be instantiated to replace it.
    /// - Note: Subtype of this instance can conform to `ViewLifecycleAware` to allow display handling.
    var containedView: UIView? { get set }

    /// A renderer which generates `containedView`.
    /// - note: Underlying type of this instance can conform to `ComponentLifecycleAware` to allow display handling.
    var component: AnyRenderable? { get set }
}

extension BentoReusableView {
    /// Uses `component` to either replace `containedView` with a new one or reuse it.
    func bind(_ component: AnyRenderable?) {
        self.component = component
        if let component = component {
            let renderingView: UIView

            if let view = containedView, type(of: view) == component.viewType {
                renderingView = view
            } else {
                renderingView = component.viewType.generate()
                containedView = renderingView
            }

            component.render(in: renderingView)
        } else {
            containedView = nil
        }
    }

    func willDisplayView() {
        component?
            .cast(to: ComponentLifecycleAware.self)?
            .willDisplayItem()

        containedView?.enumerateAllViewsAndSelf { view in
            (view as? ViewLifecycleAware)?.willDisplayView()
        }
    }

    func didEndDisplayingView() {
        component?
            .cast(to: ComponentLifecycleAware.self)?
            .didEndDisplayingItem()

        containedView?.enumerateAllViewsAndSelf { view in
            (view as? ViewLifecycleAware)?.didEndDisplayingView()
        }
    }
}

extension BentoReusableView where Self: UIView {
    /// - important: This should be invoked whenever `containedView` is changed.
    func containedViewDidChange(from old: UIView?, to new: UIView?) {
        func add(_ view: UIView) {
            contentView.addSubview(view)
            view.pinToEdges(of: contentView)
        }

        switch (old, new) {
        case let (oldView?, newView?) where UIView.areAnimationsEnabled:
            UIView.transition(
                with: self,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: {
                    oldView.removeFromSuperview()
                    add(newView)
                },
                completion: nil
            )
        default:
            old?.removeFromSuperview()

            if let new = new {
                add(new)
            }
        }
    }
}

fileprivate extension UIView {
    func enumerateAllViewsAndSelf(_ action: (UIView) -> Void) {
        action(self)

        for view in subviews {
            view.enumerateAllViewsAndSelf(action)
        }
    }
}
