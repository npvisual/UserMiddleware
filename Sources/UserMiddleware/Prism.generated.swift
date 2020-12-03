// Generated using Sourcery 1.0.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

extension UserAction {
    public var create: Void? {
        get {
            guard case .create = self else { return nil }
            return ()
        }
    }

    public var isCreate: Bool {
        self.create != nil
    }

    public var delete: Void? {
        get {
            guard case .delete = self else { return nil }
            return ()
        }
    }

    public var isDelete: Bool {
        self.delete != nil
    }

    public var update: [UserInfo.CodingKeys: Any]? {
        get {
            guard case let .update(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .update = self, let newValue = newValue else { return }
            self = .update(newValue)
        }
    }

    public var isUpdate: Bool {
        self.update != nil
    }

    public var register: String? {
        get {
            guard case let .register(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .register = self, let newValue = newValue else { return }
            self = .register(newValue)
        }
    }

    public var isRegister: Bool {
        self.register != nil
    }

    public var stateChanged: UserState? {
        get {
            guard case let .stateChanged(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .stateChanged = self, let newValue = newValue else { return }
            self = .stateChanged(newValue)
        }
    }

    public var isStateChanged: Bool {
        self.stateChanged != nil
    }

}
