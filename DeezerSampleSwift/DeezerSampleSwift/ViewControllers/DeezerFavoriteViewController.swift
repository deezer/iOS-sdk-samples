import UIKit

class DeezerFavoriteViewController: BaseViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    
    private lazy var objects: [DeezerObject] = {
        var _objects = [DeezerObject]()
        _objects.append(DeezerObject(title: "Favorites Playlist", type: .playlist))
        _objects.append(DeezerObject(title: "Favorites Albums", type: .album))
        _objects.append(DeezerObject(title: "Favorites Artists", type: .artist))
        _objects.append(DeezerObject(title: "Favorites Mixes", type: .mix))
        return _objects
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select what you need"
        setupTableView()
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
}

// MARK: - UITableViewDataSource

extension DeezerFavoriteViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = objects[indexPath.row].title
        return cell
    }
    
}

// MARK: - UITableViewDelegate

extension DeezerFavoriteViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        NavigationManager.showObjectList(from: self, object: objects[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
}
