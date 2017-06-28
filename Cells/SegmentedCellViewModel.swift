import ReactiveSwift
import enum Result.NoError

public struct SegmentedCellViewModel {

    public struct Option {
        let title: String
        let imageName: String

        public init(title: String, imageName: String) {
            self.title = title
            self.imageName = imageName
        }
    }

    let visualDependencies: VisualDependenciesProtocol

    let options: [Option]
    let selectedIndex: Property<Int>
    let selection: Action<Int, Void, NoError>

    public init(options: [Option], selectedIndex: Int = 0, visualDependencies: VisualDependenciesProtocol) {
        precondition(options.isEmpty == false)
        precondition(options.indices.contains(selectedIndex))

        self.options = options
        self.visualDependencies = visualDependencies

        let selectedIndex = MutableProperty(selectedIndex)

        self.selectedIndex = Property(capturing: selectedIndex)

        self.selection = Action { index in
            selectedIndex.swap(index)
            return .empty
        }
    }
}

extension SegmentedCellViewModel.Option: Equatable {

    public static func ==(lhs: SegmentedCellViewModel.Option, rhs: SegmentedCellViewModel.Option) -> Bool {
        return lhs.title == rhs.title && lhs.imageName == rhs.imageName
    }
}
