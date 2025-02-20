import UIKit
import SDWebImage

class FigurineCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!

    func configure(with figurine: (name: String, imageUrl: String, price: Double)) {
        nameLabel.text = figurine.name
        priceLabel.text = figurine.price > 0 ? "£\(String(format: "%.2f", figurine.price))" : "Price not available"

        if let url = URL(string: figurine.imageUrl) {
            imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
        }
    }
}
