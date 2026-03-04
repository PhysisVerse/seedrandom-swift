# SeedRandom (Swift)

A lightweight Swift implementation of the default **`seedrandom(seed)`** algorithm used in JavaScript.

This package provides deterministic, seed-based random number generation compatible with the default generator from the popular JavaScript library **seedrandom**.

The primary goal of this project is **cross-platform reproducibility** — allowing Swift applications (Metal, SwiftUI, etc.) to generate the **same seeded random streams** used in JavaScript environments such as **Three.js**, **React-Three-Fiber**, and other WebGL workflows.

This makes it possible to reproduce procedural scenes, simulations, or generative effects identically between web and native platforms.

---

# Features

• Deterministic seeded random number generation
• Compatible with JavaScript `seedrandom(seed)` default generator
• Pure Swift implementation (no dependencies)
• Distributed as a Swift Package Manager library
• Suitable for procedural graphics, simulations, generative art, and deterministic testing

---

# Installation

Add the package to your project using **Swift Package Manager**.

### In Xcode

1. Open your project
2. Select **File → Add Package Dependencies**
3. Enter the repository URL

```
https://github.com/YOUR_USERNAME/seedrandom-swift
```

4. Select the latest version and add the package to your target.

---

# Usage

Import the module:

```swift
import SeedRandom
```

Create a seeded random generator:

```swift
let rng = SeedRandom("hello.")
```

Generate deterministic random values:

```swift
let value = rng.nextDouble()
```

Calling `nextDouble()` repeatedly produces the same sequence for the same seed.

---

# API

### `SeedRandom(seed: String)`

Creates a deterministic random number generator.

Example:

```swift
let rng = SeedRandom("liquid-randomness")
```

---

### `nextDouble()`

Returns a deterministic floating-point number in the range:

```
0 ≤ value < 1
```

Example:

```swift
let value = rng.nextDouble()
```

Equivalent JavaScript usage:

```javascript
const rng = seedrandom("seed")
rng()
```

---

### `quick()`

Returns a 32-bit precision floating-point number.

Example:

```swift
let value = rng.quick()
```

Equivalent JavaScript usage:

```javascript
rng.quick()
```

---

### `int32()`

Returns a signed 32-bit integer.

Example:

```swift
let value = rng.int32()
```

Equivalent JavaScript usage:

```javascript
rng.int32()
```

---

# Example

```swift
import SeedRandom

let rng = SeedRandom("example-seed")

for _ in 0..<5 {
    print(rng.nextDouble())
}
```

Running this code will always produce the same sequence for the same seed.

---

# Typical Use Cases

This library is useful when deterministic randomness is required across different platforms.

Examples include:

• Procedural graphics and shaders
• Generative art
• Game logic
• Simulation systems
• Cross-platform rendering pipelines
• Reproducing WebGL scenes in native Metal or SwiftUI applications

---

# Implementation Notes

This package implements the **default ARC4-based generator used by `seedrandom.js`**.

Only the core generator is included.
Alternative algorithms distributed with the original project (Alea, xor4096, xorshift, etc.) are not implemented here.

The focus of this package is compatibility with the default usage pattern:

```javascript
const rng = seedrandom(seed)
rng()
```

---

# Attribution

This project is a Swift implementation inspired by the original **seedrandom** JavaScript library.

Original project:

https://github.com/davidbau/seedrandom

Copyright © David Bau

The original library is released under the MIT License.

This Swift implementation re-creates the deterministic generator behavior for use in native Apple platform applications.
