import Foundation

public extension BasicFuture {
    convenience init(asyncOn queue: DispatchQueue, _ block: @escaping (BasicPromise<Value>) -> Void) {
        self.init(asyncOn: queue.asyncContext, block)
    }
    
    convenience init(asyncOn queue: DispatchQueue, _ block: @escaping () -> Value) {
        self.init(asyncOn: queue.asyncContext, block)
    }
    
    func on(_ queue: DispatchQueue) -> BasicFuture {
        return changeContext(queue.asyncContext)
    }
    
    func asyncAfter(deadline: DispatchTime, on queue: DispatchQueue) -> BasicFuture {
        return async { resolve in
            queue.asyncAfter(deadline: deadline, execute: resolve)
        }
    }
    
    func timed() -> BasicFuture<(value: Value, elapsedTime: TimeInterval)> {
        let start = Date()
        return map { ($0, Date().timeIntervalSince(start)) }
    }
    
    @available(macOS 10.12, iOS 10.0, *)
    func delayed(by interval: TimeInterval) -> BasicFuture {
        return async { resolve in
            Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in resolve() }
        }
    }
}
