import Foundation
import Security

public struct SeedRandomState: Codable, Hashable {
    public var i: UInt8
    public var j: UInt8
    public var S: [UInt8]   // length 256

    public init(i: UInt8, j: UInt8, S: [UInt8]) {
        self.i = i
        self.j = j
        self.S = S
    }
}

struct ARC4 {
    var i: UInt8 = 0
    var j: UInt8 = 0
    var S: [UInt8] = Array(0...255)

    init(key: [UInt8]) {
        var key = key
        if key.isEmpty { key = [0] }

        var j: UInt8 = 0
        for idx in 0..<256 {
            let si = S[idx]
            let k = key[idx % key.count]
            j = j &+ k &+ si
            S.swapAt(idx, Int(j))
        }

        // Discard initial 256 bytes (RC4-drop[256] like seedrandom.js)
        _ = g(256)
    }

    mutating func g(_ count: Int) -> UInt64 {
        var r: UInt64 = 0
        for _ in 0..<count {
            i = i &+ 1
            let t = S[Int(i)]
            j = j &+ t
            S[Int(i)] = S[Int(j)]
            S[Int(j)] = t
            let out = S[Int(S[Int(i)] &+ S[Int(j)])]
            r = r * 256 + UInt64(out)
        }
        return r
    }

    func state() -> SeedRandomState {
        SeedRandomState(i: i, j: j, S: S)
    }

    mutating func load(_ st: SeedRandomState) {
        i = st.i
        j = st.j
        S = st.S
    }
}

public final class SeedRandom {
    // Constants aligned to seedrandom.js
    private static let width: Double = 256.0
    private static let chunks: Int = 6
    private static let digits: Double = 52.0
    private static let startDenom: Double = pow(width, Double(chunks))   // 256^6 = 2^48
    private static let significance: Double = pow(2.0, digits)           // 2^52
    private static let overflow: Double = significance * 2.0             // 2^53

    private var arc4: ARC4

    /// Deterministic PRNG from a seed string.
    public init(_ seed: String) {
        let key = Self.mixkey(seed: seed, keySize: 256)
        self.arc4 = ARC4(key: key)
    }

    /// OS-random seed (not intended to match JS autoseed byte-for-byte).
    public convenience init() {
        self.init(Self.autoSeedString())
    }

    /// Restore from saved state.
    public init(state: SeedRandomState) {
        self.arc4 = ARC4(key: [0])
        self.arc4.load(state)
    }

    /// Double in [0, 1)
    public func nextDouble() -> Double {
        var n = Double(arc4.g(Self.chunks))   // < 2^48
        var d = Self.startDenom
        var x: Double = 0

        while n < Self.significance {
            n = (n + x) * Self.width
            d *= Self.width
            x = Double(arc4.g(1))
        }

        while n >= Self.overflow {
            n /= 2.0
            d /= 2.0
            x = floor(x / 2.0)
        }

        return (n + x) / d
    }

    /// 32-bit signed integer
    public func int32() -> Int32 {
        let u = UInt32(truncatingIfNeeded: arc4.g(4))
        return Int32(bitPattern: u)
    }

    /// Quick double: 32 bits / 2^32
    public func quick() -> Double {
        Double(arc4.g(4)) / 4294967296.0
    }

    public func state() -> SeedRandomState {
        arc4.state()
    }
}

// MARK: - Seeding helpers

extension SeedRandom {
    /// mixkey: uses UTF-16 code units (matches JS charCodeAt behavior)
    fileprivate static func mixkey(seed: String, keySize: Int) -> [UInt8] {
        var key = Array(repeating: UInt8(0), count: keySize)
        var smear: Int = 0
        var j = 0

        for cu in seed.utf16 {
            let idx = j & 255
            let prev = Int(key[idx])
            smear ^= prev * 19
            let mixed = (smear + Int(cu)) & 255
            key[idx] = UInt8(mixed)
            j += 1
        }
        return key
    }

    fileprivate static func autoSeedString() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
    }
}
