import UIKit

class DeezerSearchViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    
    private lazy var searchBar : UISearchBar = {
        var _searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44))
        _searchBar.delegate = self
        _searchBar.placeholder = "Search \(type.rawValue)"
        tableView.tableHeaderView = _searchBar
        return _searchBar
    }()
    
    private var data: [Any]? {
        didSet {
            tableViewDelegate?.data = data
        }
    }
    private var objectResultSearch: DZRObjectList? {
        didSet {
            getData()
        }
    }
    private var tableViewDelegate: DeezerObjectTableViewDelegate?
    var type: DeezerObjectType = .all

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchBar.endEditing(false)
        definesPresentationContext = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        definesPresentationContext = false
    }
    
    func setupTableView() {
        let object = DeezerObject(title: "search", type: type, object: nil)
        tableViewDelegate = DeezerObjectTableViewDelegate(viewController: self, object: object)
        tableView.delegate = tableViewDelegate
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
    
    func search(_ query: String) {
        type.searchObjectList(queryText: query) {[weak self] (objectList, error) in
            guard let objectList = objectList, let strongSelf = self else {
                if let error = error {
                    self?.present(error: error)
                }
                return
            }
            strongSelf.objectResultSearch = objectList
        }
    }
    
    func getData() {
        guard let objectResultSearch = self.objectResultSearch else {
            return
        }
        DeezerManager.sharedInstance.getData(fromObjectList: objectResultSearch) {[unowned self] (data, error) in
            guard let data = data else {
                if let error = error {
                    self.present(error: error)
                }
                return
            }
            self.data = data
            self.tableView.reloadData()
        }
    }
    
    func clearData() {
        data?.removeAll()
        tableView.reloadData()
    }
    
}

// MARK: - UITableViewDataSource

extension DeezerSearchViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        guard let deezerObject = data?[indexPath.row] as? DZRObject else {
            return cell
        }
        cell.textLabel?.text = deezerObject.description
        return cell
    }
    
}

// MARK: UISearchBarDelegate

extension DeezerSearchViewController: UISearchBarDelegate {

    func clearSearchBar() {
        searchBar.text = ""
        searchBar.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        clearSearchBar()
        clearData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            search(searchText)
        } else {
            clearData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = false
        return true
    }
}
