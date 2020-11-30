import os.log
import Foundation
import Combine

import SwiftRex

// MARK: - ACTIONS
//sourcery: Prism
public enum UserAction {
    case start
    case create
    case delete
    case update
    case read
    case stateChanged(UserState)
}

public struct UserState: Codable, Equatable, Hashable {
    public let localId: String
    public let beaconid: UInt16?
    public let email: String
    public let givenName: String
    public let familyName: String
    public var displayName: String { givenName + familyName }
    public let families: [String: Bool]?
    public let tracking: Bool?
    
    public init(
        localId: String,
        beaconid: UInt16? = nil,
        email: String,
        givenName: String,
        familyName: String,
        families: [String: Bool]? = nil,
        tracking: Bool? = true
    )
    {
        self.localId = localId
        self.beaconid = beaconid
        self.email = email
        self.givenName = givenName
        self.familyName = familyName
        self.families = families
        self.tracking = tracking
    }
}

// MARK: - ERRORS
public enum UserError: Error {
    case somethingSomething
}

// MARK: - PROTOCOL
public protocol UserStorage {
    func create(
        key: String,
        givenName: String,
        familyName: String,
        email: String
    ) -> AnyPublisher<String, UserError>
    func read(key: String) -> AnyPublisher<String, UserError>
    func update(
        key: String,
        params: [String: Any]
    ) -> AnyPublisher<String, UserError>
    func delete(key: String) -> AnyPublisher<Void, UserError>
    func userChangeListener(key: String) -> AnyPublisher<UserState, UserError>
}

// MARK: - MIDDLEWARE
public class UserMiddleware: Middleware {
    public typealias InputActionType = UserAction
    public typealias OutputActionType = UserAction
    public typealias StateType = UserState?
    
    private static let logger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "UserMiddleware")

    private var output: AnyActionHandler<OutputActionType>? = nil
    private var getState: GetState<StateType>? = nil

    private var provider: UserStorage
    
    private var currentUserKey: PassthroughSubject<String, Never> = PassthroughSubject()
    private var stateChangeCancellable: AnyCancellable?
    private var userOperationCancellable: AnyCancellable?

    public init(provider: UserStorage) {
        self.provider = provider
    }
    
    public func receiveContext(getState: @escaping GetState<StateType>, output: AnyActionHandler<OutputActionType>) {
        os_log(
            "Receiving context...",
            log: UserMiddleware.logger,
            type: .debug
        )
        self.getState = getState
        self.output = output
        self.stateChangeCancellable = currentUserKey
            .flatMap { key in
                self.provider.userChangeListener(key: key)
            }
            .sink { (completion: Subscribers.Completion<UserError>) in
                var result: String = "success"
                if case Subscribers.Completion.failure = completion {
                    result = "failure"
                }
                os_log(
                    "State change completion with %s...",
                    log: UserMiddleware.logger,
                    type: .debug,
                    result
                )
            } receiveValue: { user in
                os_log(
                    "State change receiving value for user : %s...",
                    log: UserMiddleware.logger,
                    type: .debug,
                    String(describing: user.localId)
                )
                self.output?.dispatch(.stateChanged(user))
            }
    }
    
    public func handle(
        action: InputActionType,
        from dispatcher: ActionSource,
        afterReducer : inout AfterReducer
    ) {
        switch action {
            case .start:
                if let state = getState,
                   let oldState = state() {
                    os_log(
                        "Starting the user service for : %s ...",
                        log: UserMiddleware.logger,
                        type: .debug,
                        String(describing: oldState.localId)
                    )
                    currentUserKey.send(oldState.localId)
                }
            default:
                os_log(
                    "Not handling this case : %s ...",
                    log: UserMiddleware.logger,
                    type: .debug,
                    String(describing: action)
                )
                break
        }
        
        afterReducer = .do { [self] in
            if let state = getState,
               let newState = state() {
                os_log(
                    "Calling afterReducer closure...",
                    log: UserMiddleware.logger,
                    type: .debug
                )
                switch action {
                    case .start:
                        currentUserKey.send(newState.localId)
                    case .create:
                        userOperationCancellable = provider
                            .create(
                                key: newState.localId,
                                givenName: newState.givenName,
                                familyName: newState.familyName,
                                email: newState.email
                            )
                            .sink { (completion: Subscribers.Completion<UserError>) in
                                var result: String = "success"
                                if case Subscribers.Completion.failure = completion {
                                    result = "failure"
                                }
                                os_log(
                                    "User creation completion with %s...",
                                    log: UserMiddleware.logger,
                                    type: .debug,
                                    result
                                )
                            } receiveValue: { ref in
                                os_log(
                                    "User creation receiving ref : %s...",
                                    log: UserMiddleware.logger,
                                    type: .debug,
                                    String(describing: ref)
                                )
                            }
                    default:
                        os_log(
                            "Apparently not handling this case either : %s...",
                            log: UserMiddleware.logger,
                            type: .debug,
                            String(describing: action)
                        )
                        break
                }
            }
        }
    }
}
