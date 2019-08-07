//
//  ChatController.swift
//  Bonjour
//
//  Created by Artem Maglyovany on 11/2/17.
//  Copyright © 2017 Artem Maglyovany. All rights reserved.
//

import UIKit

private let cellIdentifier = "MessageCell"

private struct Message {
    var message: String
    var isFromMe: Bool
}

class ChatController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    
    private var messages: [Message] = [Message]()
    weak var connection: Connection? {
        didSet {
            if let connection = connection {
                title = connection.name
                connection.delegate = self
                connection.open()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideKeyboard)))
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            var keyboardHeight: CGFloat = 0
            if (endFrame?.origin.y)! < UIScreen.main.bounds.size.height {
                keyboardHeight = endFrame?.size.height ?? 0
            }
            
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: {
                            self.view.frame.origin = CGPoint(x: 0, y: -keyboardHeight)
                            
            }, completion: nil)
        }
    }
    
    @objc func close() {
        if let connection = connection {
            connection.delegate = nil
            connection.close()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func send(_ sender: UIButton) {
        guard let text = textField.text else { return }
        
        if let connection = connection {
            textField.text = nil
            
            appendMessage(Message(message: text, isFromMe: true))
            
            connection.sendData("\(text)\n".utf8Data!)
        } else {
            dismiss(animated: true) {
                let alert = UIAlertController(title: "Error", message: "There is no connection", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                
                AppDelegate.shared?.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }

    private func appendMessage(_ message: Message) {
        messages.append(message)
        
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension ChatController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let message = messages[indexPath.row]
    
        if message.isFromMe {
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = message.message
        } else {
            cell.textLabel?.text = message.message
            cell.detailTextLabel?.text = nil
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ChatController: UITableViewDelegate { }

// MARK: - ConnectionDelegate

extension ChatController: ConnectionDelegate {
    func connection(_ connection: Connection, didReceiveData data: Data) {
        appendMessage(Message(message: String(data: data, encoding: .utf8)!, isFromMe: false))
    }
    
    func connection(_ connection: Connection, willCloseWithError error: NSError?) {
        dismiss(animated: true) {
            if let error = error {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                
                AppDelegate.shared?.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }
}
