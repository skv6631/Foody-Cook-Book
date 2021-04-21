//
//  ViewController.swift
//  FoodyCookBook
//
//  Created by E5000416 on 21/04/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var mealImage: UIImageView!
    var loader:UIAlertController?
    var randomMeal:MealObject?
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getRandomMeal()
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
            }
        }
    }

}

