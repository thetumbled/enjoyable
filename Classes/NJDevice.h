//
//  NJDevice.h
//  Enjoy
//
//  Created by Sam McCall on 4/05/09.
//  Copyright 2009 University of Otago. All rights reserved.
//

#import "NJInputPathElement.h"

@class NJInput;

@interface NJDevice : NJInputPathElement

/// Returns nil for devices that should not be listed (e.g. macOS synthetic GamePad).
- (id)initWithDevice:(IOHIDDeviceRef)device;

+ (BOOL)shouldIgnoreHIDDevice:(IOHIDDeviceRef)device;

@property (nonatomic, assign) int index;
@property (nonatomic, assign) IOHIDDeviceRef device;

- (NJInput *)handlerForEvent:(IOHIDValueRef)value;
- (NJInput *)inputForEvent:(IOHIDValueRef)value;

@end
