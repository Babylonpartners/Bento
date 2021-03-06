import UIKit
import FlexibleDiff

public typealias TableViewAdapter<SectionID: Hashable, ItemID: Hashable> = TableViewAdapterBase<SectionID, ItemID> & UITableViewDataSource & UITableViewDelegate

private let knownSupplements: Set<Supplement> = [.header, .footer]

open class TableViewAdapterBase<SectionID: Hashable, ItemID: Hashable>
    : NSObject, AdapterStoreOwner, FocusEligibilitySourceImplementing {
    public var sections: [Section<SectionID, ItemID>] {
        return store.sections
    }

    internal private(set) weak var tableView: UITableView?
    internal var store: AdapterStore<SectionID, ItemID>

    // NOTE: Required initializer is necessary for instantiation via metatype to work. In Swift 4.2, it appears that
    //       there is a compiler type checking hole which allows instantiation via a non-required initializer.

    public required init(with tableView: UITableView) {
        self.store = AdapterStore()
        self.tableView = tableView
        super.init()
    }

    func update(sections: [Section<SectionID, ItemID>], with animation: TableViewAnimation) {
        guard let tableView = tableView else {
            return
        }
        let diff = TableViewSectionDiff(oldSections: self.sections,
                                        newSections: sections,
                                        animation: animation)
        diff.apply(to: tableView, updateAdapter: { changeset in
            self.store.update(with: sections, knownSupplements: knownSupplements, changeset: changeset)
        })
    }

    func update(sections: [Section<SectionID, ItemID>]) {
        store.update(with: sections, knownSupplements: knownSupplements, changeset: nil)
        tableView?.reloadData()
    }

    @objc(numberOfSectionsInTableView:)
    open func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    @objc open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    @objc(tableView:cellForRowAtIndexPath:)
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let component = node(at: indexPath).component
        let reuseIdentifier = component.fullyQualifiedTypeName

        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? TableViewContainerCell else {
            tableView.register(TableViewContainerCell.self, forCellReuseIdentifier: reuseIdentifier)
            return self.tableView(tableView, cellForRowAt: indexPath)
        }

        cell.bind(component)
        return cell
    }

    @objc open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return sections[section].supplements[.header]
            .map { self.render($0, in: tableView) }
    }

    @objc open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return sections[section].supplements[.footer]
            .map { self.render($0, in: tableView) }
    }

    @objc open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch store.size(for: .header, inSection: section) {
        case .noCachedResult:
            return tableView.sectionHeaderHeight
        case .doesNotExist:
            return .leastNonzeroMagnitude
        case let .size(size):
            return size.height
        }
    }

    @objc open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch store.size(for: .footer, inSection: section) {
        case .noCachedResult:
            return tableView.sectionFooterHeight
        case .doesNotExist:
            return .leastNonzeroMagnitude
        case let .size(size):
            return size.height
        }
    }

    @objc(tableView:heightForRowAtIndexPath:)
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return store.size(forItemAt: indexPath).map { $0.height + tableView.separatorHeight }
            ?? tableView.rowHeight
    }

    @objc open func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        switch store.size(for: .header, inSection: section, allowEstimation: true) {
        case .noCachedResult:
            return tableView.estimatedSectionHeaderHeight
        case .doesNotExist:
            return .leastNonzeroMagnitude
        case let .size(size):
            return size.height
        }
    }

    @objc open func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        switch store.size(for: .footer, inSection: section, allowEstimation: true) {
        case .noCachedResult:
            return tableView.estimatedSectionFooterHeight
        case .doesNotExist:
            return .leastNonzeroMagnitude
        case let .size(size):
            return size.height
        }
    }

    @objc(tableView:estimatedHeightForRowAtIndexPath:)
    open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return store.size(forItemAt: indexPath, allowEstimation: true)
            .map { $0.height + tableView.separatorHeight }
            ?? tableView.estimatedRowHeight
    }

    @objc(tableView:editActionsForRowAtIndexPath:)
    open func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let item = sections[indexPath.section].items[indexPath.row]
        guard let component = item.component(as: Deletable.self) else {
            return nil
        }

        return [
            UITableViewRowAction(style: .destructive, title: component.deleteActionText) { (_, indexPath) in
                self.deleteRow(at: indexPath, actionPerformed: nil)
            }
        ]
    }

    @available(iOS 11.0, *)
    @objc(tableView:trailingSwipeActionsConfigurationForRowAtIndexPath:)
    open func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = sections[indexPath.section].items[indexPath.row]
        guard let component = item.component(as: Deletable.self) else {
            return UISwipeActionsConfiguration(actions: [])
        }

        let action = UIContextualAction(style: .destructive, title: component.deleteActionText) { (_, _, actionPerformed) in
            self.deleteRow(at: indexPath, actionPerformed: actionPerformed)
        }

        return UISwipeActionsConfiguration(actions: [action])
    }

    @objc(tableView:willDisplayCell:forRowAtIndexPath:)
    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? BentoReusableView else { return }
        cell.willDisplayView()
    }

    @objc open  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? BentoReusableView else { return }
        view.willDisplayView()
    }

    @objc
    open func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let view = view as? BentoReusableView else { return }
        view.willDisplayView()
    }

    @objc(tableView:didEndDisplayingCell:forRowAtIndexPath:)
    open func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? BentoReusableView else { return }
        cell.didEndDisplayingView()
    }

    @objc
    open func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? BentoReusableView else { return }
        view.didEndDisplayingView()
    }

    @objc
    open func tableView(_ tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int) {
        guard let view = view as? BentoReusableView else { return }
        view.didEndDisplayingView()
    }

    @objc(tableView:shouldShowMenuForRowAtIndexPath:)
    open func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        guard let component = sections[indexPath.section].items[indexPath.row].component(as: MenuItemsResponding.self) else {
            return false
        }
        UIMenuController.shared.menuItems = component.menuItems
        return true
    }

    @objc(tableView:canPerformAction:forRowAtIndexPath:withSender:)
    open func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        guard let component = sections[indexPath.section].items[indexPath.row].component(as: MenuItemsResponding.self) else {
            return false
        }

        return component.responds(to: action)
    }

    @objc(tableView:performAction:forRowAtIndexPath:withSender:)
    open func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {}

    public func invalidateSize(at indexPath: IndexPath) {
        store.invalidateSize(at: indexPath)
    }

    private func deleteRow(at indexPath: IndexPath, actionPerformed: ((Bool) -> Void)?) {
        let item = sections[indexPath.section].items[indexPath.row]
        guard let component = item.component(as: Deletable.self) else {
            actionPerformed?(false)
            return
        }

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            component.delete()
        }
        store.removeItem(at: indexPath)
        tableView?.deleteRows(at: [indexPath], with: .left)
        actionPerformed?(true)
        CATransaction.commit()
    }

    private func node(at indexPath: IndexPath) -> Node<ItemID> {
        return sections[indexPath.section].items[indexPath.row]
    }

    private func render(_ component: AnyRenderable, in tableView: UITableView) -> UIView {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: component.fullyQualifiedTypeName) as? TableViewHeaderFooterView else {
            tableView.register(TableViewHeaderFooterView.self,
                               forHeaderFooterViewReuseIdentifier: component.fullyQualifiedTypeName)
            return render(component, in: tableView)
        }
        header.bind(component)
        return header
    }
}

internal final class BentoTableViewAdapter<SectionID: Hashable, ItemID: Hashable>
    : TableViewAdapterBase<SectionID, ItemID>,
      UITableViewDataSource,
      UITableViewDelegate
{}

extension UITableView {
    fileprivate var separatorHeight: CGFloat {
        return separatorStyle != .none ? 1.0 / contentScaleFactor : 0.0
    }
}
