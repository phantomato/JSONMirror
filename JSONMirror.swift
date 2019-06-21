//
//  JSONMirror.swift
//  JSONMirror
//
//  Created by Roman Tkachenko on 21/06/2019.
//  Copyright © 2019 AwesomeDeveloper. All rights reserved.
//

import Foundation

class JSONMirror {
    
    // MARK: - Internal
    
    struct Options: OptionSet {
        let rawValue: Int
        
        static let excludeEmptyFields = Options(rawValue: 1 << 0)
    }
    
    class func reflect<T>(_ any: T, options: Options? = nil) -> Any? {
        return reflect(element: any, options: options)
    }
    
    // MARK: - Private
    
    private class func reflect<T>(element: T, options: Options?) -> Any? {
        guard let result = value(for: element, options: options) else {
            return nil
        }
        switch result {
        case _ as [Any], _ as [AnyHashable: Any]:
            return result
        default:
            return [result]
        }
    }
    
    private class func value(for any: Any, options: Options?) -> Any? {
        let mirror = Mirror(reflecting: any)
        if mirror.children.isEmpty {
            switch any {
            case _ as Int, _ as Int64, _ as Int32, _ as Double, _ as Float, _ as String, _ as Bool:
                return any
            case _ as Optional<Any>:
                if options?.contains(.excludeEmptyFields) ?? false {
                    return nil
                } else {
                    fallthrough
                }
            default:
                return String(describing: any)
            }
        } else if let displayStyle = mirror.displayStyle {
            switch displayStyle {
            case .class, .dictionary, .struct:
                return dictionary(from: mirror, options: options)
            case .collection, .set, .tuple:
                return array(from: mirror, options: options)
            case .enum, .optional:
                return value(for: mirror.children.first!.value, options: options)
            @unknown default:
                print("not matched")
                return nil
            }
        } else {
            return nil
        }
    }
    
    private class func dictionary(from mirror: Mirror, options: Options?) -> [AnyHashable: Any] {
        return mirror.children.reduce(into: [AnyHashable: Any]()) {
            var key: AnyHashable!
            var value: Any!
            if let label = $1.label {
                key = label
                value = $1.value
            } else {
                let array = self.array(from: Mirror(reflecting: $1.value), options: options)
                guard 2 <= array.count,
                    let newKey = (array[0] as? AnyHashable) else {
                        return
                }
                key = newKey
                value = array[1]
            }
            if let value = self.value(for: value!, options: options) {
                $0[key] = value
            }
        }
    }
    
    private class func array(from mirror: Mirror, options: Options?) -> [Any] {
        return mirror.children.compactMap {
            value(for: $0.value, options: options)
        }
    }
}
