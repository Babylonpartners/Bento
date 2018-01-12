import UIKit
import ReactiveSwift
import enum Result.NoError
import BabylonFoundation

extension ActionInputCell: NibLoadableCell {}

final class ActionInputCell: FormItemCell {
    fileprivate var viewModel: ActionInputCellViewModel!

    @IBOutlet var iconViewHorizontalConstraints: [NSLayoutConstraint]!
    @IBOutlet var miniatureIconWidthConstraint: NSLayoutConstraint!
    @IBOutlet var largeRoundAvatarWidthConstraint: NSLayoutConstraint!
    @IBOutlet var largeRoundAvatarVerticalMarginConstraints: [NSLayoutConstraint]!
    @IBOutlet var stackView: UIStackView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var subIconView: UIImageView!
    @IBOutlet weak var statusIconView: UIImageView!

    @IBOutlet var titleLabelMinWidthConstraint: NSLayoutConstraint!
    @IBOutlet var statusIconPresenceConstraints: [NSLayoutConstraint]!

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var preferredSeparatorLeadingAnchor: NSLayoutXAxisAnchor {
        return titleLabel.leadingAnchor
    }

    func setup(viewModel: ActionInputCellViewModel) {
        self.viewModel = viewModel
        viewModel.applyTitleStyle(to: titleLabel)
        viewModel.applyInputStyle(to: subtitleLabel)
        accessoryType = viewModel.accessory
        selectionStyle = viewModel.selectionStyle

        let isCellEnabled = viewModel.isSelected.isEnabled.and(isFormEnabled).producer
            .take(until: reactive.prepareForReuse)
        reactive.isUserInteractionEnabled <~ isCellEnabled

        titleLabel.reactive.text <~ viewModel.title.producer
            .take(until: reactive.prepareForReuse)

        if let input = viewModel.input {
            subtitleLabel.isHidden = false
            subtitleLabel.reactive.text <~ input.producer
                .observe(on: UIScheduler())
                .take(until: reactive.prepareForReuse)
        } else {
            subtitleLabel.isHidden = true
        }

        if viewModel.isVertical {
            self.stackView.axis = .vertical
            self.stackView.alignment = .leading
            self.stackView.isBaselineRelativeArrangement = true
            self.stackView.spacing = 18
        } else {
            self.stackView.axis = .horizontal
            self.stackView.alignment = .center
            self.stackView.isBaselineRelativeArrangement = false
            self.stackView.spacing = 10
        }

        contentView.layoutMargins = viewModel.isVerticallySpacious
            ? UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
            : UIEdgeInsets(top: 8.0, left: 16.0, bottom: 8.0, right: 16.0)

        var activatingConstraints: [NSLayoutConstraint] = []
        var deactivatingConstraints: [NSLayoutConstraint] = []

        switch viewModel.inputTextAlignment {
        case .leading, .center:
            activatingConstraints.append(titleLabelMinWidthConstraint)
        case .trailing:
            deactivatingConstraints.append(titleLabelMinWidthConstraint)
        }

        if let subIcon = viewModel.subIcon {
            self.subIconView.image = subIcon
            subIconView.isHidden = false
        } else {
            subIconView.isHidden = true
            self.subIconView.image = nil
        }

        switch (viewModel.iconStyle, viewModel.icon) {
        case let (.largeRoundAvatar, icon?):
            deactivatingConstraints.append(miniatureIconWidthConstraint)
            activatingConstraints.append(largeRoundAvatarWidthConstraint)
            activatingConstraints.append(contentsOf: largeRoundAvatarVerticalMarginConstraints)
            activatingConstraints.append(contentsOf: iconViewHorizontalConstraints)

            iconView.layer.cornerRadius = largeRoundAvatarWidthConstraint.constant / 2.0
            iconView.isHidden = false
            iconView.contentMode = .scaleAspectFill
            iconView.reactive.image <~ icon
                .observe(on: UIScheduler())
                .take(until: reactive.prepareForReuse)
        case let (_, icon):
            // The icon view still participates in Auto Layout even if it is hidden. So
            // if the icon is not present, the miniature style would be forced so that
            // the icon view can practically have no effect on the cell height.
            deactivatingConstraints.append(largeRoundAvatarWidthConstraint)
            deactivatingConstraints.append(contentsOf: largeRoundAvatarVerticalMarginConstraints)
            activatingConstraints.append(miniatureIconWidthConstraint)
            iconView.layer.cornerRadius = 0.0
            iconView.contentMode = .center

            if let icon = icon {
                iconView.isHidden = false
                iconView.reactive.image <~ icon
                    .observe(on: UIScheduler())
                    .take(until: reactive.prepareForReuse)
                activatingConstraints.append(contentsOf: iconViewHorizontalConstraints)
            } else {
                iconView.isHidden = true
                deactivatingConstraints.append(contentsOf: iconViewHorizontalConstraints)
            }
        }

        NSLayoutConstraint.deactivate(deactivatingConstraints)
        NSLayoutConstraint.activate(activatingConstraints)

        let hidesAccessoryWhenDisabled = viewModel.hidesAccessoryWhenDisabled
        let updateAccessoryView = { [weak self] (isExecuting: Bool, isEnabled: Bool) in
            let makeActivityIndicatorView: () -> UIActivityIndicatorView = {
                let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
                activityIndicator.startAnimating()
                return activityIndicator
            }
            self?.accessoryView = isExecuting ? makeActivityIndicatorView() : nil
            self?.accessoryType = isEnabled || hidesAccessoryWhenDisabled.isFalse ? viewModel.accessory : .none
        }

        SignalProducer.combineLatest(viewModel.isSelected.isExecuting,
                                     isCellEnabled)
            .observe(on: UIScheduler())
            .take(until: reactive.prepareForReuse)
            .startWithValues(updateAccessoryView)

        statusIconView.isHidden = viewModel.statusIcon.isNil
        statusIconView.image = viewModel.statusIcon

        if viewModel.statusIcon.isNil {
            NSLayoutConstraint.deactivate(statusIconPresenceConstraints)
        } else {
            NSLayoutConstraint.activate(statusIconPresenceConstraints)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            becomeFirstResponder()
            resignFirstResponder()
            viewModel.isSelected.apply().start()
        }
    }
}

extension ActionInputCell: DeletableCell {
    var canBeDeleted: Bool {
        guard let action = viewModel.wasDeleted else { return false }

        return action.isEnabled.value
    }

    public func delete() -> SignalProducer<Never, NoError> {
        guard let action = viewModel.wasDeleted,
              action.isEnabled.value else {
            return .empty
        }

        return action.apply()
            .ignoreValues()
            .ignoreError()
    }
}
