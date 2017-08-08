import UIKit
import ReactiveSwift
import ReactiveCocoa
import Result

extension NoteInputCell: NibLoadableCell {}

final class NoteInputCell: FormItemCell {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var addPhotosButton: UIButton!
    @IBOutlet weak var placeholder: UILabel!

    private var viewModel: NoteInputCellViewModel!

    internal weak var delegate: FocusableCellDelegate?
    internal weak var heightDelegate: DynamicHeightCellDelegate?

    private var contentViewHeight: NSLayoutConstraint!

    @IBOutlet var textViewHeight: NSLayoutConstraint!
    @IBOutlet var addPhotosButtonTextViewTopEdge: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        textView.delegate = self

        contentViewHeight = contentView.heightAnchor.constraint(equalToConstant: minimumHeight)
        contentViewHeight.priority = UILayoutPriorityRequired - 1
        contentViewHeight.isActive = true

        updateContentViewHeight()
    }

    func setup(viewModel: NoteInputCellViewModel) {
        self.viewModel = viewModel
        placeholder.text = viewModel.placeholder
        textView.text = ""

        let isEnabled = viewModel.isEnabled.and(isFormEnabled)
        isEnabled.producer
            .take(until: reactive.prepareForReuse)
            .startWithSignal { isEnabled, _ in
                textView.reactive.isUserInteractionEnabled <~ isEnabled
                addPhotosButton.reactive.isEnabled <~ isEnabled
            }

        // FIXME: Remove workaround in ReactiveSwift 2.0.
        //
        // `continuousTextValues` yields the current text for all text field control
        // events. This may lead to deadlock in `Action` internally, if:
        //
        // 1. `isFormEnabled` is derived from `isExecuting` of an `Action`; and
        // 2. `viewModel.text` feeds into the `Action` as its state.
        //
        // So we filter any value being yielded after the form is disabled.
        //
        // This has been fixed in RAS 2.0.
        // https://github.com/ReactiveCocoa/ReactiveSwift/pull/400
        // https://github.com/ReactiveCocoa/ReactiveSwift/pull/481
        viewModel.text <~ textView.reactive.continuousTextValues
            .filterMap { isEnabled.value ? $0 : nil }
            .take(until: reactive.prepareForReuse)

        viewModel.text.producer
            .take(until: reactive.prepareForReuse)
            .observe(on: UIScheduler())
            .startWithValues { [weak self] value in
                guard let strongSelf = self else { return }
                if !strongSelf.textView.isFirstResponder {
                    strongSelf.textView.text = value
                    // Update the text view as if the user has made changes to it.
                    strongSelf.textViewDidChange(strongSelf.textView, isUserInteraction: false)
                }
            }

        addPhotosButton.reactive.pressed = CocoaAction(viewModel.addPhotosAction)

        viewModel.applyStyle(to: textView)
        viewModel.applyStyle(to: placeholder)
        viewModel.applyStyle(to: addPhotosButton)
        viewModel.applyBackgroundColor(to: [self, textView])

        self.selectionStyle = viewModel.selectionStyle
    }

    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        updateContentViewHeight()
    }

    override func layoutSubviews() {
        updateContentViewHeight()
        super.layoutSubviews()
    }

    @discardableResult
    fileprivate func updateContentViewHeight() -> CGFloat {
        let intrinsicContentSize = textView.intrinsicContentSize

        if intrinsicContentSize.height != textViewHeight.constant {
            // Offset the content height so that when its text view grows beyond the
            // minimum height, an illusion of the text view staying in place would be
            // maintained.
            let minimumTextViewHeight = ("" as NSString).size(attributes: [NSFontAttributeName: textView.font!]).height
            let minimumContentHeight = max(minimumHeight - layoutMargins.top - layoutMargins.bottom, minimumTextViewHeight)
            let inset = max(minimumContentHeight - minimumTextViewHeight, 0.0)

            addPhotosButtonTextViewTopEdge.constant = (minimumTextViewHeight - addPhotosButton.frame.height) / 2.0

            // When the system-wide content size category has changed, and the app resumes
            // to the foreground, the UITextView refuses to resize itself regardless of
            // tons of means being attempted. So now its height is maintained explicitly.
            textViewHeight.constant = intrinsicContentSize.height
            contentViewHeight.constant = max(minimumHeight, inset + intrinsicContentSize.height + layoutMargins.top + layoutMargins.bottom)

            return textView.bounds.height - intrinsicContentSize.height
        }

        return 0.0
    }
}

extension NoteInputCell: FocusableCell {
    func focus() {
        textView.becomeFirstResponder()
    }
}

extension NoteInputCell: DynamicHeightCell, UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textViewDidChange(textView, isUserInteraction: true)
    }

    func textViewDidChange(_ textView: UITextView, isUserInteraction: Bool) {
        placeholder.isHidden = textView.text != nil ? !textView.text.isEmpty : false
        let delta = updateContentViewHeight()

        if isUserInteraction {
            heightDelegate?.dynamicHeightCellHeightDidChange(delta: delta)
        }
    }
}

@IBDesignable class NoteInputCellTextView: UITextView {
    override func awakeFromNib() {
        super.awakeFromNib()

        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
    }
}
