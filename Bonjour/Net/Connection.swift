//
//  Connection.swift
//  Bonjour
//
//  Created by Artem Maglyovany on 11/2/17.
//  Copyright © 2017 Artem Maglyovany. All rights reserved.
//

import Foundation

private var connectionId: Int = 0

private func getConnectionNewName() -> String {
    connectionId = connectionId + 1
    return "Connection #\(connectionId)"
}

protocol ConnectionDelegate: class {
    func connection(_ connection: Connection, didReceiveData data: Data)
    func connection(_ connection: Connection, willCloseWithError error: NSError?)
}

class Connection: NSObject {
    
    static let errorDomain = "ConnectionErrorDomain"
    
    let name: String = getConnectionNewName()
    
    private(set) var inputStream: InputStream
    private(set) var outputStream: OutputStream
    
    private let inputBufferCapacity: Int
    private var inputBuffer: UnsafeMutablePointer<UInt8>?
    
    private let outputBufferCapacity: Int
    private var outputBuffer: UnsafeMutablePointer<UInt8>?
    private var outputData: Data
    
    private(set) var isOpen: Bool = false
    
    weak var delegate: ConnectionDelegate?
    
    init(inputStream: InputStream, inputBufferCapacity: Int = 1024, outputStream: OutputStream, outputBufferCapacity: Int = 1024) {
        self.inputStream = inputStream
        self.outputStream = outputStream

        self.inputBufferCapacity = inputBufferCapacity
        self.outputBufferCapacity = outputBufferCapacity
        
        outputData = Data()
        
        super.init()
    }
    
    func open() {
        guard !isOpen else { return }
        
        inputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: inputBufferCapacity)
        outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: outputBufferCapacity)
        
        inputStream.delegate = self
        outputStream.delegate = self
        
        inputStream.schedule(in: .current, forMode: .defaultRunLoopMode)
        outputStream.schedule(in: .current, forMode: .defaultRunLoopMode)
        
        inputStream.open()
        outputStream.open()
        
        isOpen = true
    }
    
    func close() {
        closeWithError(nil, notifiy: false)
    }
    
    internal func closeWithError(_ error: NSError?, notifiy: Bool = true) {
        guard isOpen else { return }
        
        if notifiy {
            delegate?.connection(self, willCloseWithError: error)
        }
        
        inputStream.delegate = nil
        outputStream.delegate = nil
        
        inputStream.close()
        outputStream.close()
        
        inputBuffer?.deallocate(capacity: inputBufferCapacity)
        inputBuffer = nil
        
        outputBuffer?.deallocate(capacity: outputBufferCapacity)
        outputBuffer = nil
        
        isOpen = false
    }
    
    internal func processInput() {
        guard let buffer = inputBuffer else { return }
        
        var data = Data()
        var bytesRead: Int
        while inputStream.hasBytesAvailable {
            bytesRead = inputStream.read(buffer, maxLength: inputBufferCapacity)
            data.append(buffer, count: bytesRead)
        }
        
        processInputData(data)
    }
    
    internal func processInputData(_ data: Data) {
        delegate?.connection(self, didReceiveData: data)
    }
    
    func sendData(_ data: Data) {
        outputData.append(data)
        processOutput()
    }
    
    internal func processOutput() {
        guard outputStream.hasSpaceAvailable else { return }
        
        var bytesWritten: Int
        while outputStream.hasSpaceAvailable && !outputData.isEmpty {
            bytesWritten = outputStream.write(outputData.unsafeBytes, maxLength: outputData.count)
            
            if bytesWritten <= 0 {
                closeWithError(outputStream.streamError as NSError?)
            } else {
                outputData.removeSubrange(0..<bytesWritten)
            }
        }
    }
}

extension Data {
    var unsafeBytes: UnsafePointer<UInt8> { return withUnsafeBytes({ return $0 }) }
}

// MARK: - StreamDelegate

extension Connection: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard aStream == inputStream || aStream == outputStream else { return }
        
        let stream = aStream == inputStream ? "input" : "output"
        
        switch eventCode {
        case .openCompleted:
            print("\(name) opened \(stream)")
        case .hasBytesAvailable:
            print("\(name) has bytes available")
            if aStream == inputStream { processInput() }
        case .hasSpaceAvailable:
            print("\(name) has space available")
            if aStream == outputStream { processOutput() }
        case .endEncountered:
            print("\(name) EOF \(stream)")
            closeWithError(nil)
        case .errorOccurred:
            print("error \(name) \(stream) \(String(describing: aStream.streamError))")
            closeWithError(aStream.streamError as NSError?)
        default:
            break
        }
    }
}
