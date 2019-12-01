//
//  CustomLoginViewController.swift
//  Chat
//
//  Created by Hovhannes Stepanyan on 12/1/19.
//  Copyright © 2019 Hovhannes Stepanyan. All rights reserved.
//

import Foundation
import FirebaseAuth

class CustomLoginViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    var provider: String! = ""
    var loginComplition: ((Any?, Error?) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = String(format: "Login With %@", provider)
        // Do any additional setup after loading the view.
        if Auth.auth().currentUser != nil {
            performSegue(withIdentifier: "toChat", sender: nil)
//            try? Auth.auth().signOut()
        }
    }

    @IBAction func login(_ sender: UIButton) {
        if emailTextField.text?.isEmpty == true || passwordTextField.text?.isEmpty == true {
            return
        } else {
            let email = emailTextField.text!
            let password = passwordTextField.text!
            Auth.auth().signIn(withEmail: email, password: password) {[weak self] (result, error) in
//                self.dismiss(animated: true)
//                self.loginComplition(result, error)
                self?.performSegue(withIdentifier: "toChat", sender: nil)
                print("uid =", result?.user.uid)
//                try? Auth.auth().signOut()
            }
        }
    }
    
    
    @IBAction func  cancel() {
        dismiss(animated: true)
    }
}
