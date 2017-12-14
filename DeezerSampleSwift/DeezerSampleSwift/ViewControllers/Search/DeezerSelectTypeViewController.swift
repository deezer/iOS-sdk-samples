import UIKit

class DeezerSelectTypeViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    
    private lazy var typeArray: [DeezerObject] = {
        var _typeArray = [DeezerObject]()
        _typeArray.append(DeezerObject(title: "Tracks", type: .track))
        _typeArray.append(DeezerObject(title: "Albums", type: .album))
        _typeArray.append(DeezerObject(title: "Artists", type: .artist))
        _typeArray.append(DeezerObject(title: "Playlists", type: .playlist))
        _typeArray.append(DeezerObject(title: "Mixes", type: .mix))
        return _typeArray
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select a type"
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
}

extension DeezerSelectTypeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        NavigationManager.showSearch(from: self, type: typeArray[indexPath.row].type)
    }
}

extension DeezerSelectTypeViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return typeArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = typeArray[indexPath.row].title
        return cell
    }
}
