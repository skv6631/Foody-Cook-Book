//
//  ViewController.swift
//  FoodyCookBook
//
//  Created by E5000416 on 21/04/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mealImage: UIImageView!
    lazy var searchbar = UISearchBar(frame: CGRect.zero)

    var loader:UIAlertController?
    var randomMeal:MealObject?
    override func viewDidLoad() {
        super.viewDidLoad()
        addSearchIcon()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.sectionHeaderHeight = 44
        tableView.tableFooterView = UIView()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getRandomMeal()
    }
    func addSearchIcon() {
        let search = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: self, action: #selector(handleSearchAction))
        self.navigationItem.rightBarButtonItem = search
        self.navigationItem.titleView = nil
        self.navigationItem.title = "Foody Cook Book"

    }
    @objc func handleSearchAction() {
        searchbar.placeholder = "Search"
        searchbar.searchTextField.returnKeyType = .search
        searchbar.delegate = self
        searchbar.showsCancelButton = true
        navigationItem.titleView = searchbar
        self.navigationItem.rightBarButtonItem = nil


    }
    
    func prepareData(for meal:MealObject) {
        if let url = URL(string: meal.strMealThumb ?? "") {
            downloadImage(from: url)
        }
    }
}
extension ViewController {
    fileprivate func hideLoading() {
        DispatchQueue.main.async { [weak self] in
            if let _loader = self?.loader{
                _loader.dismiss(animated: true, completion: nil)
            }

        }
    }
    fileprivate func showLoading() {
        if let _loader = loader{
            self.present(_loader, animated: true, completion: nil)
        } else {
            loader = UIAlertController(title: "Fetching your meal", message: nil, preferredStyle: .alert)
            self.present(loader!, animated: true, completion: nil)
        }
    }
}
extension ViewController {
    fileprivate func getRandomMeal(){
        let randomMealURL = "https://www.themealdb.com/api/json/v1/1/random.php"
        if let url = URL(string: randomMealURL){
            showLoading()
            let task = URLSession.shared.dataTask(with: url) {[weak self] (data, response, error) in
                guard let data = data else { return }
                self?.hideLoading()
                do{
                    if let jsonResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:Any] {
                        if let object = (jsonResult["meals"] as? [NSDictionary])?.first{
                            let meal = MealObject()
                            let mirror = Mirror(reflecting: meal)
                            for child in mirror.children{
                                if let variable = child.label {
                                    meal.setValue(object[variable], forKey: variable)
                                }
                            }
                            self?.randomMeal = meal
                            self?.prepareData(for: meal)
                        }
                    }
                } catch {
                    print("error while parsing:", error.localizedDescription)
                }
            }
            task.resume()
        }
    }

    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    func downloadImage(from url: URL) {
        print("Download Started")
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            // always update the UI from the main thread
            DispatchQueue.main.async() { [weak self] in
                self?.mealImage.image = UIImage(data: data)
                self?.tableView.reloadData()
            }
        }
    }

}

extension ViewController:UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        if let meal = self.randomMeal {
            let mirror = Mirror(reflecting: meal)
            return mirror.children.count-1
        }
        return 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = .lightGray
        cell.textLabel?.numberOfLines = 0
        if let meal = self.randomMeal {
            let mirror = Mirror(reflecting: meal).children
            let filteredLabels = mirror.map({$0.value})[0..<mirror.count-1] ///eliminating  thumbnail
            cell.textLabel?.text = filteredLabels[indexPath.section] as? String ?? ""

        }
        return cell
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UILabel(frame: CGRect(x: 5, y: 0, width: tableView.frame.width - 2*5, height: 44))
        header.textAlignment = .left
        header.textColor = .gray
        if let meal = self.randomMeal {
            let mirror = Mirror(reflecting: meal).children
            let filteredLabels = mirror.map({$0.label})[0..<mirror.count-1] ///eliminating  thumbnail
            let value = filteredLabels[section]
            if let range = value?.range(of: "str") { //remove str in the starting
                header.text = filteredLabels[section]?.replacingCharacters(in: range, with: "")

            }

        }
        
        return header
    }
    
}
extension ViewController:UISearchBarDelegate{
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        let cancel = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action:#selector(searchBarCancelButtonClicked(_:)))
        self.navigationItem.setRightBarButton(cancel, animated: true)
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchbar.text?.removeAll()
        addSearchIcon()
    }

}
