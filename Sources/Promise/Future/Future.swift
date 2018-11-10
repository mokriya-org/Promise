public final class Future<Value> {
    private let result: BasicFuture<Result<Value>>
    
    init(result: BasicFuture<Result<Value>>) {
        self.result = result
    }
}

private extension Future {
    convenience init(
        context: @escaping ExecutionContext,
        _ process: (Promise<Value>) throws -> Void
    ) {
        let result = BasicPromise<Result<Value>>(future: .pending)
        self.init(result: result.future.changeContext(context))
        
        let promise = Promise(result: result)
        promise.do { try process(promise) }
    }
}

internal extension Future {
    var testableResult: Result<Value>? {
        return result.testableValue
    }
}

public extension Future {
    static var pending: Future {
        return Future(result: .pending)
    }
    
    static func make() -> (future: Future, promise: Promise<Value>) {
        let result = BasicPromise<Result<Value>>(future: .pending)
        let future = Future<Value>(result: result.future)
        let promise = Promise(result: result)
        
        return (future, promise)
    }
    
    convenience init(_ future: BasicFuture<Value>) {
        self.init(result: future.map(Result.value))
    }
    
    convenience init(_ process: (Promise<Value>) throws -> Void) {
        let result = BasicPromise<Result<Value>>(future: .pending)
        self.init(result: result.future)
        
        let promise = Promise(result: result)
        promise.do { try process(promise) }
    }
    
    @discardableResult
    func then(_ handler: @escaping (Value) -> Void) -> Future {
        result.then { result in
            if case .value(let value) = result {
                handler(value)
            }
        }
        
        return self
    }
    
    @discardableResult
    func `catch`(_ handler: @escaping (Error) -> Void) -> Future {
        result.then { result in
            if case .error(let error) = result {
                handler(error)
            }
        }
        
        return self
    }
    
    @discardableResult
    func always(_ handler: @escaping () -> Void) -> Future {
        result.then { _ in
            handler()
        }
        
        return self
    }
    
    func changeContext(_ context: @escaping ExecutionContext) -> Future {
        return Future(context: context) { promise in
            promise.observe(self)
        }
    }
}
