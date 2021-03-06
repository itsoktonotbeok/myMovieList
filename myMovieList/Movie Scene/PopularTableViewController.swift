//
//  MovieListViewController.swift
//  myMovieList
//
//  Created by Zhiyi Chen on 3/30/22.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage

class PopularTableViewController: UITableViewController {
    
    var movies: [Movie] = []
    let popularMoviePath = "https://api.themoviedb.org/3/movie/popular?api_key=5500afde12ee9320ce1ca032c03b6165&language=en-US&page=1"
    let currentUID = Auth.auth().currentUser?.uid
    let db = Database.database().reference()
    let sr = Storage.storage().reference()
    var isFavorite = false

    @IBOutlet var popularTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popularTableView.delegate = self
        popularTableView.dataSource = self
        
        fetchPopularMoviesData()
        createNavHeader()
    }
    
    func fetchPopularMoviesData() {
        guard let popularMovieURL = URL(string: popularMoviePath) else { return }
        ApiService.shared.getMoviesDataFrom(with: popularMovieURL, completion: { result in
            switch result {
            case .success(let movieList):
                DispatchQueue.main.async {
                    self.movies = movieList.movies
                    self.popularTableView.reloadData()
                }
            case .failure(let error):
                print("Error processing json data: \(error)")
            }
        })
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "popularCell", for: indexPath) as! PopularTableViewCell
        let movie = movies[indexPath.row]
        cell.setCellWithValuesOf(movie)
        cell.favoriteButton.tag = indexPath.row
        cell.favoriteButton.addTarget(self, action: #selector(didTapFavorite(sender:)), for: .touchUpInside)
        return cell
    }
    
    @objc func didTapFavorite(sender: UIButton) {
        // print(sender.tag)
        let movieID = movies[sender.tag].id
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            sender.setImage(UIImage(systemName: "heart.fill"), for: .selected)
            db.child("users").child(currentUID!).child("favorites").child((String(movieID!))).setValue("Yes")
        }
        else {
            sender.setImage(UIImage(systemName: "heart"), for: .normal)
            db.child("users").child(currentUID!).child("favorites").child((String(movieID!))).removeValue()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            movies.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "popularToDetail":
            if let indexPath = tableView.indexPathForSelectedRow {
                let movie = movies[indexPath.row]
                let detailViewController = segue.destination as! DetailViewController
                detailViewController.movie = movie
            }
        case "movieToProfile":
            let profileViewController = segue.destination as! ProfileViewController
            profileViewController.currentUID = currentUID!
        default:
            preconditionFailure("Unexpected segue identifier.")
        }
    }
    
    func createNavHeader() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(didTapLogout))
        ]
        StorageManager.shared.downloadProfilePicture(with: currentUID!) { image in
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: 0.0, y: 0.0, width: 24, height: 24)
            button.setImage(image, for: .normal)
            button.addTarget(self, action: #selector(self.didTapProfilePhoto), for: .touchUpInside)
            let barButtonItem = UIBarButtonItem(customView: button)
            let currWidth = barButtonItem.customView?.widthAnchor.constraint(equalToConstant: 24)
            currWidth?.isActive = true
            let currHeight = barButtonItem.customView?.heightAnchor.constraint(equalToConstant: 24)
            currHeight?.isActive = true
            self.navigationItem.rightBarButtonItems?.append(barButtonItem)
        }
    }
    
    @objc func didTapLogout() {
        do {
            try? Auth.auth().signOut()
            let navViewController = self.storyboard?.instantiateViewController(withIdentifier: "loginpage") as? UINavigationController
            self.view.window?.rootViewController = navViewController
            self.view.window?.makeKeyAndVisible()
        }
    }
    
    @objc func didTapProfilePhoto() {
        do {
            performSegue(withIdentifier: "movieToProfile", sender: self)
        }
    }
}
