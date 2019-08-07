//
//  DiscoveringController.swift
//  Bonjour
//
//  Created by Artem Maglyovany on 11/1/17.
//  Copyright © 2017 Artem Maglyovany. All rights reserved.
//

import UIKit

private let cellIdentifier = "ServiceCell"

class DiscoveringController: UITableViewController {

    let server = Server(name: UIDevice.current.name, type: .test)
    let browser = ServicesBrowser(type: .test)
    
    var services: Set<NetService> = Set()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        server.delegate = self
        
        browser.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: .UIApplicationWillResignActive, object: nil)
    }
    
    private func updateServicesWith(_ newServices: Set<NetService>?) {
        services.removeAll()
        if let newServices = newServices {
            services.formUnion(newServices)
        }
        
        tableView.reloadData()
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        browser.start()
        server.start()
    }
    
    @objc func applicationWillResignActive(_ notification: Notification) {
        browser.stop()
        server.stop()
    }
    
    func startConnection(_ connection: Connection) {
        let chatController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatController") as! ChatController
        chatController.connection = connection
        present(UINavigationController(rootViewController: chatController), animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource

extension DiscoveringController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let service = services[services.indices.index(services.startIndex, offsetBy: indexPath.row)]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = service.name
        return cell
    }
}

extension DiscoveringController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let service = services[services.index(services.startIndex, offsetBy: indexPath.row)]
        
        if let connection = server.createConnectionWithService(service) {
            startConnection(connection)
        } else {
            let alert = UIAlertController(title: "Error", message: "Connection with \(service.name) could not be established.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - ServicesBrowserDelegate -

extension DiscoveringController: ServicesBrowserDelegate {
    func servicesBrowser(_ browser: ServicesBrowser, didStopWithError error: NSError?) {
        updateServicesWith(nil)
    }
    
    func servicesBrowser(_ browser: ServicesBrowser, didUpdateServices services: Set<NetService>) {
        if let service = server.netService {
            print("didUpdateServices contains server \(services.contains(service))")
        }
        updateServicesWith(services.filter({ $0 != server.netService }))
    }
}

// MARK: - ServerDelegate -

extension DiscoveringController: ServerDelegate {
    func serverDidStart(_ server: Server) {
        print("server \(server.name) didStart")
    }
    
    func serverDidStop(_ server: Server, withError error: NSError?) {
        print("server \(server.name) didStop\(error?.localizedDescription ?? "")")
    }
    
    func server(_ server: Server, isAcceptConnection connection: Connection) -> Bool {
        startConnection(connection)
        return true
    }
}
