import UIKit
import ReactiveCocoa

public final class SegmentedCell: UITableViewCell {

    let stackView: UIStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isLayoutMarginsRelativeArrangement = true
        $0.distribution = .fillProportionally
        $0.layoutMargins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return $0
    }(UIStackView())

    var viewModel: SegmentedCellViewModel!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        addSubview(stackView)

        addConstraints([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            ])
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(viewModel: SegmentedCellViewModel) {
        self.viewModel = viewModel

        generateButtons()
            .map { [$0] }
            .joined(separator: [generateSeparator()])
            .forEach(stackView.addArrangedSubview)
    }

    private func generateButtons() -> [UIButton] {
        return viewModel.options.enumerated().map { index, option in
            let button = UIButton(type: .custom)
            viewModel.visualDependencies.styles.segmentedCellButton.apply(to: button)
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
            button.setTitle(option.title, for: .normal)
            button.setImage(UIImage(named: option.imageName), for: .normal)
            button.setImage(UIImage(named: option.imageName)?.withRenderingMode(.alwaysTemplate), for: .selected)
            button.reactive.isSelected <~ viewModel.selectedIndex.map { $0 == index }
            button.reactive.pressed = CocoaAction(viewModel.selection, input: index)
            return button
        }
    }

    private func generateSeparator() -> UIView {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.widthAnchor.constraint(equalToConstant: 1.0).isActive = true
        separator.backgroundColor = Colors.hintGrey
        return separator
    }
}

extension SegmentedCell: ReusableCell {}
