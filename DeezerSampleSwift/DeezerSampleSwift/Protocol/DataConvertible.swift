import UIKit

protocol DataConvertible {
    init?(data: Data)
    var data: Data { get }
}

extension DataConvertible {
    
    init?(data: Data) {
        guard data.count == MemoryLayout<Self>.size else { return nil }
        self = data.withUnsafeBytes { $0.pointee }
    }
    
    var data: Data {
        var value = self
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension String: DataConvertible {
    init?(data: Data) {
        self.init(data: data, encoding: .utf8)
    }
    
    var data: Data {
        // Note: a conversion to UTF-8 cannot fail.
        return self.data(using: .utf8)!
    }
}

extension Double: DataConvertible {}
extension Int: DataConvertible {}
extension Date: DataConvertible {}
