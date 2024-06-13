import Foundation
import UIKit

extension UIViewController {
   func setUpNavigationBar(title: String) {
      let playerImage = UIBarButtonItem(image: nil, style: UIBarButtonItem.Style.plain, target: self, action: nil)
      self.navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
      self.navigationController?.navigationBar.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
      self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.0)]
      self.navigationController?.navigationBar.topItem?.title = title
      self.navigationController?.navigationBar.isTranslucent = false
      self.navigationController?.navigationBar.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
      self.navigationItem.leftBarButtonItem = playerImage
   }
}
