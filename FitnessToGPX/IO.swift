import Darwin
import Foundation

struct IOError: Error {
    private let errnoCode: CInt

    init(errno: CInt) {
        errnoCode = errno
    }

    static func fromErrno() -> IOError {
        IOError(errno: errno)
    }
}

extension IOError: CustomStringConvertible {
    var description: String {
        if let errorDescC = strerror(errnoCode) {
            return "\(String(cString: errorDescC)) (errno: \(errnoCode))"
        } else {
            return "Broken strerror, unknown error: \(errnoCode)"
        }
    }
}

extension IOError: LocalizedError {
    var errorDescription: String? { description }
}

final class File {

    enum Mode: String {
        case read = "r"
        case write = "w"
        case append = "a"
        case readExtended = "r+"
        case writeExtended = "w+"
        case appendExtended = "a+"
    }

    private let handle: UnsafeMutablePointer<FILE>
    private var isOpen = true

    deinit {
        close()
    }

    convenience init(path: URL, mode: Mode = .read) throws {
        try self.init(path: path.path, mode: mode)
    }

    init(path: String, mode: Mode) throws {
        let handle = path.withCString { pathCStr in
            mode.rawValue.withCString { modeCStr in
                fopen(pathCStr, modeCStr)
            }
        }
        if let handle = handle {
            self.handle = handle
        } else {
            throw IOError.fromErrno()
        }
        isOpen = true
    }

    func close() {
        if isOpen {
            fclose(handle)
            isOpen = false
        }
    }

    func flush() throws {
        if fflush(handle) == EOF {
            throw IOError(errno: ferror(handle))
        }
    }

    func writeUTF8(_ string: String) throws {
        var string = string
        try string.withUTF8 { buffer in
            if fwrite(buffer.baseAddress, 1, buffer.count, handle) == EOF {
                throw IOError(errno: ferror(handle))
            }
        }
    }
}
