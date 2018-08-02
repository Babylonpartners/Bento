import UIKit
import FlexibleDiff

public typealias TableViewAdapter<SectionId: Hashable, RowId: Hashable> = TableViewAdapterBase<SectionId, RowId> & UITableViewDataSource & UITableViewDelegate

open class TableViewAdapterBase<SectionId: Hashable, RowId: Hashable>
    : NSObject,
      FocusEligibilitySourceImplementing {
    public final var sections: [Section<SectionId, RowId>] = []
    internal weak var tableView: UITableView?

    public init(with tableView: UITableView) {
        self.sections = []
        self.tableView = tableView
        super.init()
    }

    func update(sections: [Section<SectionId, RowId>], with animation: TableViewAnimation) {
        guard let tableView = tableView else {
            return
        }
        let diff = TableViewSectionDiff(oldSections: self.sections,
                                        newSections: sections,
                                        animation: animation)
        self.sections = sections
        diff.apply(to: tableView)
    }

    func update(sections: [Section<SectionId, RowId>]) {
        self.sections = sections
        tableView?.reloadData()
    }

    @objc(numberOfSectionsInTableView:)
    open func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    @objc open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    @objc(tableView:cellForRowAtIndexPath:)
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let component = node(at: indexPath).component
        let reuseIdentifier = component.reuseIdentifier
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? TableViewContainerCell else {
            tableView.register(TableViewContainerCell.self, forCellReuseIdentifier: reuseIdentifier)
            return self.tableView(tableView, cellForRowAt: indexPath)
        }
        let componentView: UIView
        if let containedView = cell.containedView {
            componentView = containedView
        } else {
            componentView = component.generate()
            cell.install(view: componentView)
        }
        component.render(in: componentView)
        return cell

    }

    @objc open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return sections[section].header
            .map {
                return self.render(node: $0, in: tableView)
            }
    }

    @objc open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return sections[section].footer
            .map {
                return self.render(node: $0, in: tableView)
            }
    }

    @objc open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sections[section].header == nil ? CGFloat.leastNonzeroMagnitude : UITableViewAutomaticDimension
    }

    @objc open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return sections[section].footer == nil ? CGFloat.leastNonzeroMagnitude : UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let row = sections[indexPath.section].rows[indexPath.row]
        guard let component = row.component(as: Deletable.self),
              component.canBeDeleted else {
            return nil
        }

        return [
            UITableViewRowAction(style: .destructive, title: component.deleteActionText) { (_, indexPath) in
                self.deleteRow(at: indexPath, actionPerformed: nil)
            }
        ]
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let row = sections[indexPath.section].rows[indexPath.row]
        guard let component = row.component(as: Deletable.self),
              component.canBeDeleted else {
            return UISwipeActionsConfiguration(actions: [])
        }

        let action = UIContextualAction(style: .destructive, title: component.deleteActionText) { (_, _, actionPerformed) in
            self.deleteRow(at: indexPath, actionPerformed: actionPerformed)
        }

        return UISwipeActionsConfiguration(actions: [action])
    }

    private func deleteRow(at indexPath: IndexPath, actionPerformed: ((Bool) -> Void)?) {
        let row = sections[indexPath.section].rows[indexPath.row]
        guard let component = row.component(as: Deletable.self) else {
            actionPerformed?(false)
            return
        }

        component.delete()
        sections[indexPath.section].rows.remove(at: indexPath.row)
        tableView?.deleteRows(at: [indexPath], with: .left)
        actionPerformed?(true)
    }

    private func node(at indexPath: IndexPath) -> Node<RowId> {
        return sections[indexPath.section].rows[indexPath.row]
    }
    
    private func render(node: AnyRenderable, in tableView: UITableView) -> UIView {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: node.reuseIdentifier) as? TableViewHeaderFooterView else {
            tableView.register(TableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: node.reuseIdentifier)
            return render(node: node, in: tableView)
        }
        let componentView: UIView
        if let containedView = header.containedView {
            componentView = containedView
        } else {
            componentView = node.generate()
            header.install(view: componentView)
        }
        node.render(in: componentView)
        return header
    }
}

internal final class BentoTableViewAdapter<SectionId: Hashable, RowId: Hashable>
    : TableViewAdapterBase<SectionId, RowId>,
      UITableViewDataSource,
      UITableViewDelegate
{}
