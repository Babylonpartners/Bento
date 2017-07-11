import ReactiveSwift
import enum Result.NoError

public protocol FocusableCellDelegate: class {
    /// Whether `cell` has a succeeding `FocusableCell`.
    ///
    /// - note:  The cell is not necessarily its next adjacent cell.
    ///
    /// - returns: `true` if `cell` has a succeeding `FocusableCell` in the form. `false`
    ///            otherwise.
    func focusableCellHasSuccessor(_ cell: FocusableCell) -> Bool

    /// `cell` is about to yield its (subview's) first responder status.
    ///
    /// - returns: `true` if `cell` should proceed on resigning the status. `false` if
    ///            the delegate takes control of the resigning process.
    func focusableCellWillResignFirstResponder(_ cell: FocusableCell) -> Bool
}

public protocol FocusableCell: class {
    var delegate: FocusableCellDelegate? { get set }

    func focus()
}

protocol FocusableFormComponent {
    var isPreferredForFocusing: Bool { get }
}

extension FocusableFormComponent {
    public var isPreferredForFocusing: Bool {
        return false
    }
}
