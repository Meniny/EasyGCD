
<p align="center">
  <img src="https://ooo.0o0.ooo/2017/07/20/5970681dc4468.png" alt="EasyGCD">
  <br/><a href="https://cocoapods.org/pods/EasyGCD">
  <img alt="Version" src="https://img.shields.io/badge/version-1.2.1-brightgreen.svg">
  <img alt="Author" src="https://img.shields.io/badge/author-Meniny-blue.svg">
  <img alt="Build Passing" src="https://img.shields.io/badge/build-passing-brightgreen.svg">
  <img alt="Swift" src="https://img.shields.io/badge/swift-3.0%2B-orange.svg">
  <br/>
  <img alt="Platforms" src="https://img.shields.io/badge/platform-macOS%20%7C%20iOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey.svg">
  <img alt="MIT" src="https://img.shields.io/badge/license-MIT-blue.svg">
  <br/>
  <img alt="Cocoapods" src="https://img.shields.io/badge/cocoapods-compatible-brightgreen.svg">
  <img alt="Carthage" src="https://img.shields.io/badge/carthage-working%20on-red.svg">
  <img alt="SPM" src="https://img.shields.io/badge/swift%20package%20manager-working%20on-red.svg">
  </a>
</p>

## What's this?

`EasyGCD` is a tiny library to make using GCD easier. written in Swift.

## Requirements

* iOS 8.0+
* macOS 10.10+
* watchOS 2.0+
* tvOS 9.0+
* Xcode 8 with Swift 3

## Installation

#### CocoaPods

```ruby
pod 'EasyGCD'
```

## Contribution

You are welcome to fork and submit pull requests.

## License

`EasyGCD` is open-sourced software, licensed under the `MIT` license.

## Usage

```swift
dispatch {
  // asynchronously on the main queue
}

main {
  // asynchronously on the main queue
}

global {
  // asynchronously on the global queue
}
```

```swift
import EasyGCD

func sync() {
    EasyGCD.sync(.global(qos: .background)) {
        print("sync @ background global queue")
    }
}

func async() {
    EasyGCD.async(EasyGCDQueue.global(.background)) {
        print("async @ background global queue")
    }
    EasyGCD.async {
        print("async @ main queue")
    }
}

func after() {
    EasyGCD.after(2.0) {
        print("2 seconds later")
    }
    EasyGCD.after(4, queue: .global(qos: .default)) {
        print("4 seconds later")
    }
    EasyGCD.after(DispatchTime.now() + 6, queue: .main) {
        print("6 seconds later")
    }
}

func once() {
    EasyGCD.once(token: "Once") {
        print("Once")
    }
}
```
