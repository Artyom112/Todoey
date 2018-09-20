//
//  ViewController.swift
//  Todoey
//
//  Created by Artyom Kholodkov on 9/8/18.
//  Copyright © 2018 Artyom Kholodkov. All rights reserved.
//

import UIKit
import CoreData

// since we created in the storyboards, dont need to write protocols for the table view


class TodoListViewController: UITableViewController {

    //MARK: - Global Variables and viewDidLoad
    
    var itemArray = [Item]()
    
    // we call loadItems() when we are sure that selectedCategory has a value
    var selectedCategory : Category? {
        didSet {
            loadItems()
        }
    }
    
    let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Items.plist")
    
    // uiapplecation class, shares singleton object which corresponds to the current class as an object, tapping into its delegate, we are casting it into our class AppDelegate. Now we have acess to our AppDelegate as an object.
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }

    //MARK: - Tableview Datasource Methods
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoItemCell", for: indexPath)
        
        let item = itemArray[indexPath.row]
        
        cell.textLabel?.text = item.title

        // value = condition ? valueIfTrue : valueIfFalse
        cell.accessoryType = item.done == true ? .checkmark : .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    
    //MARK: - Tableview Delegate Methods. In this function we handle placeholder
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
        
        saveItems()
        
        tableView.deselectRow(at: indexPath, animated: true)
}

    //MARK: - Add New Items. We added new items to itemArray and saved them in permanent storage

    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Todoey Item", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            // what will happen once the user clicks the Add Item button on our UI alert
            // the context where the item is going to exist. its the view context of our persistent container. We add items to context first, then commit it to persistent contatiner
            
            let newItem = Item(context: self.context)
            
            newItem.title = textField.text!
            
            newItem.done = false
            
            newItem.parentCategory = self.selectedCategory
            
            self.itemArray.append(newItem)
            
            self.saveItems()
            
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
        
    }
    
    // we need to commit our context to permanent storage inside the persistent container. C in CRUD
    func saveItems() {
        
        do {
        try context.save()
        } catch {
        print ("Error saving context \(error)")
        }
        self.tableView.reloadData()
    }
    
    //method with a default value. R in CRUD. We need to be able to load the items that belong to a certain category
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
        
        
        //This predicate is always called
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
        
        if let additionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
        } else {
            request.predicate = categoryPredicate
        }
        
        do {
        itemArray = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }
        
        tableView.reloadData()
    }

}

// MARK: - Search Bar Methods

extension TodoListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        //in order to read from the context we have to create a request, NSFetchRequest - request datatype, <Item> - returns an array of items.
        let request : NSFetchRequest<Item> = Item.fetchRequest()
        
        //to query objects using core data, we are going to look at the item attribute, %@ = searchBar.text!, the title shold partly contain the text we are searching for, cd case sensitive plus umlaut,
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        
        // we need to sort the data that comes back from the database at any order of our choice. contains an array of titles
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        //so we can try using our context to fetch the results from the persistent store that specify the rules that  our request have
        loadItems(with: request, predicate: predicate)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //text changed and is also equal to 0
        if searchBar.text?.count == 0 {
            loadItems()
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
    
}
