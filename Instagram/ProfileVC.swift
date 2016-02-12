import UIKit
import CloudKit

class ProfileVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CloudManagerDelegate {
    
    // CloudKit
    let manager = CloudManager.sharedManager
    var posts = [Post]()
    var user: User?
    var userIsFriend = false
    
    // storyboard
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var usernameTextView: UITextView!
    @IBOutlet weak var postsNumberLabel: UILabel!
    @IBOutlet weak var followersNumberLabel: UILabel!
    @IBOutlet weak var followingNumberLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.user = CloudManager.sharedManager.currentUser
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()       
        
        collectionView.delegate = self
        collectionView.dataSource = self
        setUpUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.currentlyWaitingForGetPostsToReturn = false
        CloudManager.sharedManager.delegate = self
        if !self.userIsFriend {
            self.user = CloudManager.sharedManager.currentUser
        }
        setViewsToUser()
        getPosts()
    }
    
    func setViewsToUser() {
        self.postsNumberLabel.text  = "\(self.posts.count)"
        self.usernameTextView.text = self.user?.alias
        self.imageView.image = self.user?.avatar?.circle
        guard let followings = self.user?.record.objectForKey("Followings") as? [CKReference] else { return }
        self.followingNumberLabel.text = String(followings.count)
        self.followersNumberLabel.text = String(followings.count)
    }
    
    var currentlyWaitingForGetPostsToReturn = false
    func getPosts() {
        guard let user = user else { return }
        if !currentlyWaitingForGetPostsToReturn {
            self.posts = []
            self.collectionView.reloadData()
            self.currentlyWaitingForGetPostsToReturn = true
            manager.getPostsForUser(user) { (post, error) in
                self.currentlyWaitingForGetPostsToReturn = false
            }
        }
    }
    func cloudManager(cloudManager: CloudManager, gotUser user: User?) {
        if !userIsFriend {
            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.user = user
                self.setViewsToUser()
                self.getPosts()
            }
        }
    }
    func cloudManager(cloudManager: CloudManager, gotFollowings followings: [User]?) {
        getPosts()
    }
    func cloudManager(cloudManager: CloudManager, gotAllUsers allUsers: [User]?) {}
    func cloudManager(cloudManager: CloudManager, gotFeedPost post: Post?) {}
    func cloudManager(cloudManager: CloudManager, gotUserPost post: Post?) {
        guard let post = post else { return }
        self.posts.append(post)
        self.posts.sortInPlace { (postOne, postTwo) -> Bool in
            if (postOne.postTime.compare(postTwo.postTime) == .OrderedDescending) {
                return true
            } else {
                return false
            }
        }
        NSOperationQueue.mainQueue().addOperationWithBlock {
            
            self.collectionView.reloadData()
            self.setViewsToUser()
        }
    }
    
}

