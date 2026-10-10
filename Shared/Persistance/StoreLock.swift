import Darwin
import Foundation

/// An exclusive file lock coordinating store initialization across processes.
///
/// The lock remains held for the lifetime of the instance. Acquisition never
/// waits, allowing an app or widget to retry when another process is migrating.
final class StoreLock {
    private let descriptor: Int32

    /// Creates a lock for the specified file, failing if another opener holds it.
    ///
    /// - Parameter url: The shared lock file associated with the persistent store.
    /// - Throws: A POSIX error if the file cannot be opened or locked.
    init(url: URL) throws {
        descriptor = open(url.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            let code = errno
            close(descriptor)
            throw POSIXError(POSIXErrorCode(rawValue: code) ?? .EIO)
        }
    }

    deinit {
        flock(descriptor, LOCK_UN)
        close(descriptor)
    }
}
