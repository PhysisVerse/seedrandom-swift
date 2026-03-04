import Foundation
import Security

// MARK: - State

public struct SeedRandomState: Codable, Hashable {
    public var i: UInt8
    public var j: UInt8
    public var S: [UInt8]   // must be length 256

    public init(i: UInt8, j: UInt8, S: [UInt8]) {
        self.i = i
        self.j = j
        self.S = S
    }
}

// MARK: - ARC4 (RC4-drop[256]) core used by seedrandom.js default generator

struct ARC4 {
    private(set) var i: UInt8 = 0
    private(set) var j: UInt8 = 0
    private(set) var S: [UInt8] = Array(0...255)

    init(key: [UInt8]) {
        let key = key.isEmpty ? [0] : key

        // Key-scheduling algorithm (KSA)
        var jj: UInt8 = 0
        for idx in 0..<256 {
            jj = jj &+ S[idx] &+ key[idx % key.count]
            S.swapAt(idx, Int(jj))
        }

        // RC4-drop[256] — discard initial 256 bytes WITHOUT accumulating into an integer.
        discard(256)
    }

    /// One RC4 output byte (PRGA).
    @inline(__always)
    private mutating func nextByte() -> UInt8 {
        i = i &+ 1
        let t = S[Int(i)]
        j = j &+ t
        S[Int(i)] = S[Int(j)]
        S[Int(j)] = t
        return S[Int(S[Int(i)] &+ S[Int(j)])]
    }

    /// Discard `count` bytes (used for RC4-drop[256]).
    private mutating func discard(_ count: Int) {
        for _ in 0..<count { _ = nextByte() }
    }

    /// g(count) from seedrandom.js: concatenates `count` bytes into a base-256 integer.
    /// In seedrandom usage, `count` is small (1, 4, 6). Using large counts will overflow UInt64.
    mutating func g(_ count: Int) -> UInt64 {
        precondition(count <= 8, "ARC4.g(count) supports count <= 8 (seedrandom uses 1,4,6).")
        var r: UInt64 = 0
        for _ in 0..<count {
            r = (r << 8) | UInt64(nextByte())
        }
        return r
    }

    func state() -> SeedRandomState {
        SeedRandomState(i: i, j: j, S: S)
    }

    mutating func load(_ st: SeedRandomState) {
        precondition(st.S.count == 256, "SeedRandomState.S must have length 256.")
        i = st.i
        j = st.j
        S = st.S
    }
}

// MARK: - Public API

public final class SeedRandom {
    // Constants aligned with seedrandom.js default generator
    private static let width: Double = 256.0
    private static let chunks: Int = 6
    private static let digits: Double = 52.0
    private static let startDenom: Double = pow(width, Double(chunks))   // 256^6 = 2^48
    private static let significance: Double = pow(2.0, digits)           // 2^52
    private static let overflow: Double = significance * 2.0             // 2^53

    private var arc4: ARC4

    /// Deterministic PRNG from a seed string (matches JS `seedrandom(seed)` default path).
    public init(_ seed: String) {
        let key = Self.mixkey(seed: seed, keySize: 256)
        self.arc4 = ARC4(key: key)
    }

    /// OS-random seed (convenience; not meant to match JS autoseed byte-for-byte).
    public convenience init() {
        self.init(Self.autoSeedString())
    }

    /// Restore from saved state.
    public init(state: SeedRandomState) {
        self.arc4 = ARC4(key: [0]) // placeholder; immediately overwritten
        self.arc4.load(state)
    }

    /// JS `rng()` equivalent: Double in [0, 1) with ~52 bits of randomness.
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

    /// JS `int32()`
    public func int32() -> Int32 {
        Int32(bitPattern: UInt32(truncatingIfNeeded: arc4.g(4)))
    }

    /// JS `quick()`
    public func quick() -> Double {
        Double(arc4.g(4)) / 4294967296.0
    }

    public func state() -> SeedRandomState {
        arc4.state()
    }
}

// MARK: - Seeding helpers (matches seedrandom.js mixkey behavior)

private extension SeedRandom {
    /// mixkey: uses UTF-16 code units (matches JS `charCodeAt`).
    static func mixkey(seed: String, keySize: Int) -> [UInt8] {
        var key = [UInt8](repeating: 0, count: keySize)
        var smear = 0
        var j = 0

        for cu in seed.utf16 {
            let idx = j & 255
            smear ^= Int(key[idx]) * 19
            key[idx] = UInt8((smear + Int(cu)) & 255)
            j += 1
        }
        return key
    }

    static func autoSeedString() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
    }
}
