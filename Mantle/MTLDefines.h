//
//  MTLDefines.h
//  Mantle
//
//  Created by Zachary Waldowski on 3/11/16.
//  Copyright © 2016. Some rights reserved. Licensed under MIT.
//

#import <Foundation/NSObjCRuntime.h>

#define MANTLE_PURE __attribute__((__pure__))
#define MANTLE_PRIVATE extern __attribute__((__visibility__("hidden")))
#define MANTLE_DEPRECATED(...) __attribute__((availability(macosx,deprecated=10.8,message="" __VA_ARGS__))) \
    __attribute__((availability(ios,deprecated=8.0,message="" __VA_ARGS__))) \
    __attribute__((availability(watchos,deprecated=2.0,message="" __VA_ARGS__))) \
    __attribute__((availability(tvos,deprecated=9.0,message="" __VA_ARGS__))) \
    __attribute__((availability(swift,unavailable,message="" __VA_ARGS__)))
#define MANTLE_UNAVAILABLE(...) __attribute__((availability(macosx,unavailable,message="" __VA_ARGS__))) \
    __attribute__((availability(ios,unavailable,message="" __VA_ARGS__))) \
    __attribute__((availability(watchos,unavailable,message="" __VA_ARGS__))) \
	__attribute__((availability(tvos,unavailable,message="" __VA_ARGS__))) \
	__attribute__((availability(swift,unavailable,message="" __VA_ARGS__)))
#define MANTLE_EXTENDED_INIT __attribute__((objc_method_family(init)))
