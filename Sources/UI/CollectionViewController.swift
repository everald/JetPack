import UIKit


@objc(JetPack_CollectionViewController)
public /* non-final */ class CollectionViewController: ViewController {

	private var lastLayoutedSize = CGSize()

	internal let collectionViewLayout: UICollectionViewLayout


	public init(collectionViewLayout: UICollectionViewLayout) {
		self.collectionViewLayout = collectionViewLayout

		super.init()
	}


	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}


	public var automaticallyAdjustsCollectionViewInsets = true


	public var clearsSelectionOnViewWillAppear = true


	public private(set) lazy var collectionView: UICollectionView = self.createCollectionView()


	private func createCollectionView() -> UICollectionView {
		let child = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
		child.dataSource = self
		child.delegate = self

		return child
	}


	public override func viewDidLayoutSubviewsWithAnimation(animation: Animation?) {
		super.viewDidLayoutSubviewsWithAnimation(animation)

		let bounds = view.bounds

		animation.runAlways {
			if automaticallyAdjustsCollectionViewInsets {
				collectionView.setContentInset(innerDecorationInsets, maintainingVisualContentOffset: true)
				collectionView.scrollIndicatorInsets = outerDecorationInsets
			}

			if bounds.size != lastLayoutedSize {
				lastLayoutedSize = bounds.size

				collectionView.frame = CGRect(size: bounds.size)
				collectionViewLayout.invalidateLayout()
			}
		}
	}


	public override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		if clearsSelectionOnViewWillAppear, let indexPaths = collectionView.indexPathsForSelectedItems() {
			for indexPath in indexPaths {
				collectionView.deselectItemAtIndexPath(indexPath, animated: animated)
			}
		}
	}


	public override func viewDidLoad() {
		super.viewDidLoad()

		view.addSubview(collectionView)
	}
}


extension CollectionViewController: UICollectionViewDataSource {

	public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		fatalError("override collectionView(_:cellForItemAtIndexPath:) without calling super")
	}


	public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 0
	}
}


extension CollectionViewController: UICollectionViewDelegate {}
