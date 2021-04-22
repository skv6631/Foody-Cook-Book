//
//  MealObject.swift
//  FoodyCookBook
//
//  Created by E5000416 on 21/04/21.
//

import Foundation
class MealObject:NSObject,NSCoding {
    @objc var idMeal:String?
    @objc var strMeal:String?
    @objc var strCategory:String?
    @objc var strArea:String?
    @objc var strInstructions:String?
    @objc var strMealThumb:String?
    @objc var isFavourite:Bool = false
    func encode(with coder: NSCoder) {
        coder.encode(idMeal, forKey: "idMeal")
        coder.encode(strMeal, forKey: "strMeal")
        coder.encode(strCategory, forKey: "strCategory")
        coder.encode(strArea, forKey: "strArea")
        coder.encode(strInstructions, forKey: "strInstructions")
        coder.encode(strMealThumb, forKey: "strMealThumb")
        coder.encode(isFavourite, forKey: "isFavourite")

    }
    override init() {
        super.init()
    }

    required init?(coder: NSCoder) {
        idMeal = coder.decodeObject(forKey: "idMeal") as? String
        strMeal = coder.decodeObject(forKey: "strMeal") as? String
        strCategory = coder.decodeObject(forKey: "strCategory") as? String
        strArea = coder.decodeObject(forKey: "strArea") as? String
        strInstructions = coder.decodeObject(forKey: "strInstructions") as? String
        strMealThumb = coder.decodeObject(forKey: "strMealThumb") as? String
        isFavourite = coder.decodeObject(forKey: "isFavourite") as? Bool ?? false

    }
    
}
