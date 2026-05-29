//
//  NJDevice.m
//  Enjoy
//
//  Created by Sam McCall on 4/05/09.
//

#import "NJDevice.h"

#import "NJInput.h"
#import "NJInputAnalog.h"
#import "NJInputHat.h"
#import "NJInputButton.h"

static NSArray *InputsForElement(IOHIDDeviceRef device, id parent) {
    CFArrayRef elements = IOHIDDeviceCopyMatchingElements(device, NULL, kIOHIDOptionsTypeNone);
    NSMutableArray *children = [NSMutableArray arrayWithCapacity:CFArrayGetCount(elements)];
    
    int buttons = 0;
    int axes = 0;
    int hats = 0;
    
    for (CFIndex i = 0; i < CFArrayGetCount(elements); i++) {
        IOHIDElementRef element = (IOHIDElementRef)CFArrayGetValueAtIndex(elements, i);
        IOHIDElementType type = IOHIDElementGetType(element);
        uint32_t usage = IOHIDElementGetUsage(element);
        uint32_t usagePage = IOHIDElementGetUsagePage(element);
        CFIndex max = IOHIDElementGetPhysicalMax(element);
        CFIndex min = IOHIDElementGetPhysicalMin(element);
        
        NJInput *input = nil;
        
        if (!(type == kIOHIDElementTypeInput_Misc
              || type == kIOHIDElementTypeInput_Axis
              || type == kIOHIDElementTypeInput_Button))
             continue;
        
        if (max - min == 1
            || usagePage == kHIDPage_Button
            || type == kIOHIDElementTypeInput_Button) {
            input = [[NJInputButton alloc] initWithElement:element
                                                     index:++buttons
                                                    parent:parent];
        } else if (usage == kHIDUsage_GD_Hatswitch) {
            input = [[NJInputHat alloc] initWithElement:element
                                                  index:++hats
                                                 parent:parent];
        } else if (usage >= kHIDUsage_GD_X && usage <= kHIDUsage_GD_Rz) {
            input = [[NJInputAnalog alloc] initWithElement:element
                                                     index:++axes
                                                    parent:parent];
        } else {
            continue;
        }
        
        [children addObject:input];
    }

    CFRelease(elements);
    return children;
}

static NSString *NJSanitizedProductName(NSString *product) {
    NSMutableString *s = [[product stringByTrimmingCharactersInSet:
                           [NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
    if (!s.length)
        return @"Unknown";
    [s replaceOccurrencesOfString:@":" withString:@"_"
                          options:0
                            range:NSMakeRange(0, s.length)];
    [s replaceOccurrencesOfString:@"~" withString:@"_"
                          options:0
                            range:NSMakeRange(0, s.length)];
    return s;
}

@implementation NJDevice {
    int _vendorId;
    int _productId;
    NSString *_productName;
}

+ (BOOL)shouldIgnoreHIDDevice:(IOHIDDeviceRef)dev {
    NSString *transport = (__bridge NSString *)IOHIDDeviceGetProperty(dev, CFSTR(kIOHIDTransportKey));
    if (transport.length > 0)
        return NO;
    NSString *product = (__bridge NSString *)IOHIDDeviceGetProperty(dev, CFSTR(kIOHIDProductKey));
    product = [product stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    // macOS AppleGCSyntheticDevice (e.g. GamePad-1) — not a separate physical controller.
    if ([product hasPrefix:@"GamePad"])
        return YES;
    return NO;
}

- (id)initWithDevice:(IOHIDDeviceRef)dev {
    if ([NJDevice shouldIgnoreHIDDevice:dev])
        return nil;

    NSString *name = (__bridge NSString *)IOHIDDeviceGetProperty(dev, CFSTR(kIOHIDProductKey));
    if ((self = [super initWithName:name eid:nil parent:nil])) {
        self.device = dev;
        _productName = name ?: @"";
        _vendorId = [(__bridge NSNumber *)IOHIDDeviceGetProperty(dev, CFSTR(kIOHIDVendorIDKey)) intValue];
        _productId = [(__bridge NSNumber *)IOHIDDeviceGetProperty(dev, CFSTR(kIOHIDProductIDKey)) intValue];
        self.children = InputsForElement(dev, self);
        self.index = 1;
    }
    return self;
}

- (NSString *)productKey {
    return [NSString stringWithFormat:@"%@:%04x:%04x",
            NJSanitizedProductName(_productName),
            _vendorId & 0xffff,
            _productId & 0xffff];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:NJDevice.class])
        return NO;
    NJDevice *other = object;
    return _vendorId == other->_vendorId
        && _productId == other->_productId
        && [[self productKey] isEqualToString:[other productKey]];
}

- (NSString *)name {
    NSString *display = [_productName stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!display.length)
        display = @"Unknown";
    if (_index <= 1)
        return display;
    return [NSString stringWithFormat:@"%@ #%d", display, _index];
}

- (NSString *)uid {
    NSString *key = [self productKey];
    if (_index > 1)
        return [NSString stringWithFormat:@"%@:%d", key, _index];
    return key;
}

- (NJInput *)findInputByCookie:(IOHIDElementCookie)cookie {
    for (NJInput *child in self.children)
        if (child.cookie == cookie)
            return child;
    return nil;
}

- (NJInput *)handlerForEvent:(IOHIDValueRef)value {
    NJInput *mainInput = [self inputForEvent:value];
    return [mainInput findSubInputForValue:value];
}

- (NJInput *)inputForEvent:(IOHIDValueRef)value {
    IOHIDElementRef elt = IOHIDValueGetElement(value);
    IOHIDElementCookie cookie = IOHIDElementGetCookie(elt);
    return [self findInputByCookie:cookie];
}

@end
