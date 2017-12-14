import UIKit

class DeezerObjectListViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    
    private var data: [Any]? {
        didSet {
            tableViewDelegate?.data = data
        }
    }
    private var deezerObjectList: DZRObjectList? {
        didSet {
            getData()
        }
    }
    
    private var tableViewDelegate: DeezerObjectTableViewDelegate?
    var object: DeezerObject?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = object?.title
        setupTableView()
        getObjectList()
    }
    
    func getObjectList() {
        guard let type = self.object?.type else {
            return
        }
        
        
        type.getObjectList(object: object?.object, callback: { [weak self] (deezerObjectList, error) in
            guard let deezerObjectList = deezerObjectList, let strongSelf = self else {
                print(error.debugDescription )
                return
            }
            strongSelf.deezerObjectList = deezerObjectList
        })
    }
    
    func getData() {
        guard let objectList = self.deezerObjectList else {
            return
        }
        DeezerManager.sharedInstance.getData(fromObjectList: objectList) {[weak self] (data, error) in
            guard let data = data, let strongSelf = self else {
                if let error = error {
                    self?.present(error: error)
                }
                return
            }
            
            strongSelf.data = data
            strongSelf.tableView.reloadData()
        }
    }
    
    func setupTableView() {
        tableViewDelegate = DeezerObjectTableViewDelegate(viewController: self, object: object)
        tableView.delegate = tableViewDelegate
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 50
    }
}

// MARK: - UITableViewDataSource

extension DeezerObjectListViewController: UITableViewDataSource {
    
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
