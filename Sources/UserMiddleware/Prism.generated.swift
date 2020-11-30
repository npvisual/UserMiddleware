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

    public var update: Void? {
        get {
            guard case .update = self else { return nil }
            return ()
        }
    }

    public var isUpdate: Bool {
        self.update != nil
    }

    public var read: String? {
        get {
            guard case let .read(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .read = self, let newValue = newValue else { return }
            self = .read(newValue)
        }
    }

    public var isRead: Bool {
        self.read != nil
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
