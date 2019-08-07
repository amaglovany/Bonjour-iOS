//
//  ServicesBrowser.swift
//  Bonjour
//
//  Created by Artem Maglyovany on 11/1/17.
//  Copyright © 2017 Artem Maglyovany. All rights reserved.
//

import UIKit

// MARK: - ServicesBrowserDelegate -

protocol ServicesBrowserDelegate: class {
    func servicesBrowser(_ browser: ServicesBrowser, didStopWithError error: NSError?)
    func servicesBrowser(_ browser: ServicesBrowser, didUpdateServices services: Set<NetService>)
}

// MARK: - ServicesBrowser -

class ServicesBrowser: NSObject {
    private static let localDomain = "local."
    
    let type: ServiceType
    let domain: String
    
    var isStarted: Bool { return netBrowser != nil }
    
    private(set) var services: Set<NetService> = Set()
    private(set) var netBrowser: NetServiceBrowser?
    
    weak var delegate: ServicesBrowserDelegate?
    
    init(type: ServiceType, domain: String = ServicesBrowser.localDomain, delegate: ServicesBrowserDelegate? = nil) {
        self.type = type
        self.domain = domain
        self.delegate = delegate
        
        super.init()
    }
    
    func start() {
        guard !isStarted else { return }
        
        let browser = NetServiceBrowser()
        browser.delegate = self
        browser.schedule(in: .current, forMode: .defaultRunLoopMode)
        browser.searchForServices(ofType: type.value, inDomain: domain)
        
        netBrowser = browser
    }
    
    func stop() {
        guard let browser = netBrowser else { return }
        browser.delegate = nil
        browser.stop()
        
        netBrowser = nil
        
        services.removeAll()
        
        servicesUpdated()
    }
    
    private func stopWithError(error: NSError?) {
        stop()
        
        delegate?.servicesBrowser(self, didStopWithError: error)
    }
}

// MARK: - NetServiceBrowserDelegate -

extension ServicesBrowser: NetServiceBrowserDelegate {
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("will search")
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("did stop search")
    }
    
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("did not search services of type: \(type.value) in domain: \(domain) errors: \(errorDict)")
    }
    
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        print("did find domain: \(domainString) moreComing: \(moreComing)")
    }
    
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("did find service: \(service.name) moreComing: \(moreComing)")
        if !moreComing {
            services.insert(service)
            
            servicesUpdated()
        }
    }
    
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        print("did remove domain: \(domainString) moreComing: \(moreComing)")
    }
    
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("did remove service: \(service.name) moreComing: \(moreComing)")
        if !moreComing {
            services.remove(service)
            
            servicesUpdated()
        }
    }
    
    func servicesUpdated() {
        delegate?.servicesBrowser(self, didUpdateServices: services)
    }
}
