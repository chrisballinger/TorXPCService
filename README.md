# TorXPCService

[![Build Status](https://travis-ci.org/chrisballinger/TorXPCService.svg?branch=master)](https://travis-ci.org/chrisballinger/TorXPCService)

Sandboxed Tor XPC service for embedding within macOS applications.

⚠️ **Not ready for production use.** ⚠️

Further reading:

1. [App Sandbox in Depth](https://developer.apple.com/library/mac/documentation/Security/Conceptual/AppSandboxDesignGuide/AppSandboxInDepth/AppSandboxInDepth.html)
2. [Creating XPC Services](https://developer.apple.com/library/mac/documentation/macosx/conceptual/bpsystemstartup/Chapters/CreatingXPCServices.html)
3. [XPC - objc.io](https://www.objc.io/issues/14-mac/xpc/)

## Getting Started

First install [Homebrew](http://brew.sh) and install the dependencies for building [Tor.framework](https://github.com/iCepa/Tor.framework).

```
$ brew install automake autoconf libtool gettext
```

### Embedding TorXPCService in your macOS app

Add TorXPCService as a submodule. This will also pull in the Tor.framework dependency.

```
$ git submodule add https://github.com/chrisballinger/TorXPCService.git Submodules/TorXPCService
$ git submodule update --init --recursive
```

1. From here you drag `TorXPCService.xcodeproj` into your project
2. Go to the **General** tab for your app target's settings.
2. Add `TorXPCService.xpc` in your app's **Embedded Binaries** section.
3. Add `TorXPCInterface.framework	` in your app's **Linked Frameworks and Libraries** section. This framework exports the public interface of the service, which you'll need in order to interact with it.

### Example

There is also an example app that demonstrates how to add `TorXPCService` to a project. 

Clone the repository and submodules.

```
$ git clone https://github.com/chrisballinger/TorXPCService.git
$ cd TorXPCService
$ git submodule update --init --recursive
```

There is an example app that demonstrates how to integrate `TorXPCService.xpc` and `TorXPCInterface.framework	`:

```
$ open Example/TorXPCExample.xcodeproj
```

## License

Apache 2.0