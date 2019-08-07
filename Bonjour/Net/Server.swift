//
//  Server.swift
//  Bonjour
//
//  Created by Artem Maglyovany on 11/1/17.
//  Copyright © 2017 Artem Maglyovany. All rights reserved.
//

import Foundation

protocol ServerDelegate: class {
    func serverDidStart(_ server: Server)
    func serverDidStop(_ server: Server, withError error: NSError?)
    
    func server(_ server: Server, isAcceptConnection connection: Connection) -> Bool
}

class Server: NSObject {
    static let errorDomain = "ServerErrorDomain"
    
    struct ErrorCode {
        static let connectionWasDeclinedByServer = 0
    }
    
    private static let localDomain = "local."
    
    weak var delegate: ServerDelegate?
    
    private(set) var name: String
    let type: ServiceType
    let domain: String
    
    private(set) var netService: NetService? = nil
    
    private(set) var isStarted = false
    
    private(set) var openedConnections: Set<Connection> = Set()
    
    init(name: String, type: ServiceType, domain: String = localDomain) {
        self.name = name
        self.type = type
        self.domain = domain
        super.init()
    }

    func start() {
        guard netService == nil else { return }
        
        let service = NetService(domain: domain, type: type.value, name: name)
        service.schedule(in: .current, forMode: .defaultRunLoopMode)
        service.delegate = self
        
        service.publish(options: .listenForConnections)
    }
    
    func createConnectionWithService(_ service: NetService) -> Connection? {
        var inputStream: InputStream?
        var outputStream: OutputStream?
        
        service.getInputStream(&inputStream, outputStream: &outputStream)
        
        guard let input = inputStream, let output = outputStream else { return nil }
        
        let connection = Connection(inputStream: input, outputStream: output)
        openedConnections.insert(connection)
        
        return connection
    }
    
    func stop() {
        guard let service = netService else { return }

        while !openedConnections.isEmpty {
            if let connection = openedConnections.first {
                connection.close()
                openedConnections.remove(connection)
            }
        }
        
        service.delegate = nil
        service.stop()
        
        netService = nil
    }
}

// MARK: - NetServiceDelegate -

extension Server: NetServiceDelegate {
    func netServiceWillPublish(_ sender: NetService) {
        print("- \(sender.name) netServiceWillPublish")
        netService = sender
    }
    
    func netServiceDidPublish(_ sender: NetService) {
        print("- \(sender.name) netServiceDidPublish \(String(describing: sender.hostName)):\(sender.port)")
        name = sender.name
        isStarted = true
        
        delegate?.serverDidStart(self)
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("- \(sender.name) didNotPublish: \(errorDict)")
        isStarted = false
        
        var errorDomain: Int = 0
        var errorCode: Int = 0
        var error: NSError
        
        errorDomain = 0
        if let errorDomainObj = errorDict[NetService.errorDomain] {
            errorDomain = errorDomainObj.intValue
        }
        if let errorCodeObj = errorDict[NetService.errorCode] {
            errorCode = errorCodeObj.intValue
        }
        
        if errorDomain == kCFStreamErrorDomainNetServices && errorCode != 0 {
            error = NSError(domain: kCFErrorDomainCFNetwork as String, code: errorCode, userInfo: nil)
        } else {
            error = NSError(domain: NSPOSIXErrorDomain, code: Int(ENOTTY), userInfo: nil)
        }
        
        delegate?.serverDidStop(self, withError: error)
    }
    
    func netServiceDidStop(_ sender: NetService) {
        print("- \(sender.name) didStop")
        
        isStarted = false
        
        delegate?.serverDidStop(self, withError: nil)
    }
    
    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        print("- \(sender.name) didAcceptConnectionWith")
        let connection = Connection(inputStream: inputStream, outputStream: outputStream)
        if delegate?.server(self, isAcceptConnection: connection) == true {
            openedConnections.insert(connection)
        } else {
            connection.closeWithError(NSError(domain: Server.errorDomain, code: Server.ErrorCode.connectionWasDeclinedByServer, userInfo: nil))
        }
    }
}
