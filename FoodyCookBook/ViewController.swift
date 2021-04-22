//
//  ViewController.swift
//  FoodyCookBook
//
//  Created by E5000416 on 21/04/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var noResultsFoundLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mealImage: UIImageView!
    var searchbar: UISearchBar?

    var loader:UIAlertController?
    var randomMeal:MealObject?
    override func viewDidLoad() {
        super.viewDidLoad()
        addBarButtons()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .onDrag
        tableView.estimatedRowHeight = 44
        tableView.sectionHeaderHeight = 44
        tableView.tableFooterView = UIView()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getRandomMeal()
    }
    func addBarButtons() {
        let search = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: self, action: #selector(handleSearchAction))
        let fav = UIBarButtonItem(image: UIImage(systemName: "heart"), style: .plain, target: self, action: #selector(handleFavAction))
        self.navigationItem.rightBarButtonItems = [search, fav]
        self.navigationItem.titleView = nil
        self.navigationItem.title = "Foody Cook Book"

    }
    func showAsFavourite(for sender:UIBarButtonItem ,meal:MealObject){
        let favMeals = self.fetchSavedMeals()
        let isEmpty = favMeals.filter({$0.idMeal==meal.idMeal}).isEmpty
        meal.isFavourite = !isEmpty
        if meal.isFavourite {
            sender.image = UIImage(systemName: "heart.fill")
        } else {
            sender.image = UIImage(systemName: "heart")
        }
    }
    @objc func handleFavAction(_ sender:UIBarButtonItem) {
        
        guard let meal = self.randomMeal else{
            return
        }
        var meals = fetchSavedMeals()
        if meal.isFavourite{
            meals.removeAll(where: {$0.idMeal == meal.idMeal})
            meal.isFavourite = false

        } else {
            meal.isFavourite = true
            meals.append(meal)
        }
        showAsFavourite(for: sender, meal: meal)
        let userDefaults = UserDefaults.standard
        do {
            let encodedData: Data = try NSKeyedArchiver.archivedData(withRootObject: meals, requiringSecureCoding: false)
            userDefaults.set(encodedData, forKey: "favMeals")
            userDefaults.synchronize()
        } catch {
            print("error while encoding:", error.localizedDescription)
            
        }
        
    }
    func fetchSavedMeals() -> [MealObject] {
        let userDefaults = UserDefaults.standard
        var meals = [MealObject]()
        do {
            
            if let decoded  = userDefaults.data(forKey: "favMeals") , let unarchivedFavorites = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(decoded){
                meals = unarchivedFavorites as? [MealObject] ?? []
            }
        } catch{
            print("error while decoding:", error.localizedDescription)
        }
        return meals;
    }
    @objc func handleSearchAction() {
        searchbar = UISearchBar()
        searchbar?.placeholder = "Search"
        searchbar?.searchTextField.returnKeyType = .search
        searchbar?.delegate = self
//        searchbar?.showsCancelButton = true
        navigationItem.titleView = searchbar
        self.navigationItem.rightBarButtonItems = nil
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
                self?.loader = nil
            }

        }
    }
    fileprivate func showLoading(text:String) {
        if let _loader = loader{
            self.present(_loader, animated: true, completion: nil)
        } else {
            loader = UIAlertController(title: text, message: nil, preferredStyle: .alert)
            self.present(loader!, animated: true, completion: nil)
        }
    }
}
extension ViewController {
    fileprivate func resetUI() {
        self.randomMeal = nil
        DispatchQueue.main.async { [weak self] in
            self?.noResultsFoundLabel.isHidden = true

            self?.mealImage.image = nil
        }
        
    }
    fileprivate func getMealSearch(_ text:String){
        let searchURL = "https://www.themealdb.com/api/json/v1/1/search.php?s=" + text
        if let url = URL(string: searchURL){
            showLoading(text: "Searching..")
            resetUI();
            makeRequest(url: url)
        }
    }
    func makeRequest(url: URL) {
        let task = URLSession.shared.dataTask(with: url) {[weak self] (data, response, error) in
            guard let data = data else { return }
            self?.hideLoading()
            do{
                if let jsonResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:Any] {
                    if let object = (jsonResult["meals"] as? [NSDictionary])?.first{
                        let meal = MealObject()
                        let mirror = Mirror(reflecting: meal)
                        for child in mirror.children{
                            if let variable = child.label,let value = object[variable] {
                                meal.setValue(value, forKey: variable)
                            }
                        }
                        self?.randomMeal = meal
                        self?.prepareData(for: meal)
                        if let search = self?.searchbar {
                            self?.searchBarCancelButtonClicked(search)
                        }
                    } else {
                        self?.noResultsFound()
                    }
                } else {
                    self?.noResultsFound()
                }
            } catch {
                print("error while parsing:", error.localizedDescription)
            }
        }
        task.resume()

    }
    func noResultsFound() {
        reloadTable()
        DispatchQueue.main.async { [weak self] in

            self?.noResultsFoundLabel.isHidden = false
        }
    }
    func reloadTable() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    fileprivate func getRandomMeal(){
        let randomMealURL = "https://www.themealdb.com/api/json/v1/1/random.php"
        if let url = URL(string: randomMealURL){
            showLoading(text: "Fetching your meal")
            makeRequest(url: url)
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
            DispatchQueue.main.async() { [weak self] in
                self?.mealImage.image = UIImage(data: data)
                if let fav = self?.navigationItem.rightBarButtonItems?.last,let meal = self?.randomMeal {
                    self?.showAsFavourite(for:fav, meal: meal)
                }
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
            return mirror.children.count-3
        }
        return 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = .lightGray
        cell.textLabel?.numberOfLines = 0
        if let meal = self.randomMeal {
            let mirror = Mirror(reflecting: meal).children
            let filteredLabels = mirror.map({$0.value})[1..<mirror.count-2] ///eliminating  thumbnail,isfav and id
            cell.textLabel?.text = filteredLabels[indexPath.section+1] as? String ?? ""

        }
        return cell
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UILabel(frame: CGRect(x: 5, y: 0, width: tableView.frame.width - 2*5, height: 44))
        header.textAlignment = .left
        header.textColor = .gray
        if let meal = self.randomMeal {
            let mirror = Mirror(reflecting: meal).children
            let filteredLabels = mirror.map({$0.label})[1..<mirror.count-2] ///eliminating  thumbnail
            let value = filteredLabels[section+1]
            if let range = value?.range(of: "str") { //remove str in the starting
                header.text = filteredLabels[section+1]?.replacingCharacters(in: range, with: "")

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
        searchBar.resignFirstResponder()
        if let text = searchBar.text,!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            getMealSearch(text)
        }

    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        DispatchQueue.main.async { [weak self] in
            self?.searchbar?.text?.removeAll()
            self?.addBarButtons()

        }
    }

}
