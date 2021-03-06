import UIKit

public protocol AnyRenderableConvertible {
    func asAnyRenderable() -> AnyRenderable
}

public extension AnyRenderableConvertible where Self: Renderable {
    func asAnyRenderable() -> AnyRenderable {
        return AnyRenderable(self)
    }
}

public struct AnyRenderable: Renderable {
    /// The runtime view type of the wrapped `Renderable`.
    public var viewType: NativeView.Type {
        return base.viewType
    }

    /// The runtime component type of the wrapped `Renderable`.
    public var componentType: Any.Type {
        return base.componentType
    }

    internal var fullyQualifiedTypeName: String {
        /// NOTE: `String.init(reflecting:)` gives the fully qualified type name.
        //        Tests would catch unexpeced type name printing behavior due to Swift runtime changes.
        return String(reflecting: componentType)
    }

    private let base: AnyRenderableBoxBase

    public init<Base: Renderable>(_ base: Base) {
        self.base = AnyRenderableBox(base)
    }

    init(_ base: AnyRenderableBoxBase) {
        self.base = base
    }

    public func render(in view: UIView) {
        base.render(in: view)
    }

    public func didMount(to view: UIView, storage: ViewStorage) {
        base.didMount(to: view, storage: storage)
    }

    public func willUnmount(from view: UIView, storage: ViewStorage) {
        base.willUnmount(from: view, storage: storage)
    }

    public func willDisplay(_ view: UIView) {
        base.willDisplay(view)
    }

    public func didEndDisplaying(_ view: UIView) {
        base.didEndDisplaying(view)
    }

    func cast<T>(to type: T.Type) -> T? {
        return base.cast(to: type)
    }

    func sizeBoundTo(width: CGFloat, inheritedMargins: UIEdgeInsets) -> CGSize {
        return rendered(size: CGSize(width: width, height: .greatestFiniteMagnitude),
                                 inheritedMargins: inheritedMargins)
            .systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                                     withHorizontalFittingPriority: .required,
                                     verticalFittingPriority: .defaultLow)
    }

    func sizeBoundTo(height: CGFloat, inheritedMargins: UIEdgeInsets) -> CGSize {
        return rendered(size: CGSize(width: .greatestFiniteMagnitude, height: height),
                        inheritedMargins: inheritedMargins)
            .systemLayoutSizeFitting(CGSize(width: UIView.layoutFittingCompressedSize.width, height: height),
                                     withHorizontalFittingPriority: .defaultLow,
                                     verticalFittingPriority: .required)
    }

    func sizeBoundTo(size: CGSize, inheritedMargins: UIEdgeInsets) -> CGSize {
        return rendered(size: size, inheritedMargins: inheritedMargins)
            .systemLayoutSizeFitting(size)
    }

    private func rendered(size: CGSize, inheritedMargins: UIEdgeInsets) -> UIView {
        let view = viewType.generate()
        render(in: view)

        let margins = view.layoutMargins
        view.layoutMargins = UIEdgeInsets(top: max(margins.top, inheritedMargins.top),
                                          left: max(margins.left, inheritedMargins.left),
                                          bottom: max(margins.bottom, inheritedMargins.bottom),
                                          right: max(margins.right, inheritedMargins.right))

        view.triggerPresizingLayoutPassIfNeeded(forTargetSize: size)

        return view
    }
    
    public func asAnyRenderable() -> AnyRenderable {
        return self
    }
}

class AnyRenderableBox<Base: Renderable>: AnyRenderableBoxBase {
    override var viewType: NativeView.Type {
        return (base as? AnyRenderable)?.viewType ?? Base.View.self
    }

    override var componentType: Any.Type {
        return (base as? AnyRenderable)?.componentType ?? Base.self
    }

    let base: Base

    init(_ base: Base) {
        self.base = base
        super.init()
    }

    override func render(in view: UIView) {
        base.render(in: view as! Base.View)
    }

    override func cast<T>(to type: T.Type) -> T? {
        if let anyRenderable = base as? AnyRenderable {
            return anyRenderable.cast(to: type)
        }
        return base as? T
    }

    override func didMount(to view: UIView, storage: ViewStorage) {
        base.didMount(to: view as! Base.View, storage: storage)
    }

    override func willUnmount(from view: UIView, storage: ViewStorage) {
        base.willUnmount(from: view as! Base.View, storage: storage)
    }

    override func willDisplay(_ view: UIView) {
        base.willDisplay(view as! Base.View)
    }

    override func didEndDisplaying(_ view: UIView) {
        base.didEndDisplaying(view as! Base.View)
    }
}

class AnyRenderableBoxBase {
    var viewType: NativeView.Type { fatalError() }
    var componentType: Any.Type { fatalError() }

    init() {}
    
    func render(in view: UIView) { fatalError() }
    func cast<T>(to type: T.Type) -> T? { fatalError() }
    func didMount(to view: UIView, storage: ViewStorage) { fatalError() }
    func willUnmount(from view: UIView, storage: ViewStorage) { fatalError() }
    func willDisplay(_ view: UIView) { fatalError() }
    func didEndDisplaying(_ view: UIView) { fatalError() }
}

extension AnyRenderableBox: AnyRenderableConvertible {
    func asAnyRenderable() -> AnyRenderable {
        return AnyRenderable(self)
    }
}
