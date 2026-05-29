#import "NJPermissions.h"

#import <ApplicationServices/ApplicationServices.h>
#import <AppKit/AppKit.h>

@implementation NJPermissions

+ (BOOL)hasAccessibilityPermission {
    return AXIsProcessTrusted();
}

+ (BOOL)requestAccessibilityPermission {
    if ([self hasAccessibilityPermission])
        return YES;
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    return AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
}

+ (BOOL)hasInputMonitoringPermission {
    if (@available(macOS 10.15, *))
        return CGPreflightListenEventAccess();
    return YES;
}

+ (BOOL)requestInputMonitoringPermission {
    if (@available(macOS 10.15, *)) {
        if (CGPreflightListenEventAccess())
            return YES;
        return CGRequestListenEventAccess();
    }
    return YES;
}

+ (void)openAccessibilitySettings {
    NSURL *url = [NSURL URLWithString:
        @"x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"];
    if (![NSWorkspace.sharedWorkspace openURL:url]) {
        url = [NSURL URLWithString:
            @"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"];
        [NSWorkspace.sharedWorkspace openURL:url];
    }
}

+ (void)openInputMonitoringSettings {
    NSURL *url = [NSURL URLWithString:
        @"x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ListeningEvent"];
    if (![NSWorkspace.sharedWorkspace openURL:url]) {
        url = [NSURL URLWithString:
            @"x-apple.systempreferences:com.apple.preference.security?Privacy_ListeningEvent"];
        [NSWorkspace.sharedWorkspace openURL:url];
    }
}

+ (BOOL)ensureRequiredPermissionsWithPrompt:(BOOL)prompt {
    BOOL accessibility = prompt
        ? [self requestAccessibilityPermission]
        : [self hasAccessibilityPermission];
    BOOL inputMonitoring = prompt
        ? [self requestInputMonitoringPermission]
        : [self hasInputMonitoringPermission];

    if (accessibility && inputMonitoring)
        return YES;

    if (!prompt)
        return NO;

    NSMutableArray *missing = [NSMutableArray array];
    if (!accessibility)
        [missing addObject:NSLocalizedString(
            @"Accessibility (辅助功能)", @"Missing permission name")];
    if (!inputMonitoring)
        [missing addObject:NSLocalizedString(
            @"Input Monitoring (输入监控)", @"Missing permission name")];

    NSString *message = [NSString stringWithFormat:
        NSLocalizedString(
            @"Enjoyable needs the following permissions to read gamepads and "
            @"simulate keyboard input:\n\n%@\n\n"
            @"Open System Settings, enable Enjoyable for each item, then quit "
            @"and reopen Enjoyable.",
            @"Missing permissions alert message"),
        [missing componentsJoinedByString:@"\n"]];

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(
        @"Permissions Required", @"Missing permissions alert title");
    alert.informativeText = message;
    [alert addButtonWithTitle:NSLocalizedString(@"Open Settings", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Later", nil)];

    if ([alert runModal] == NSAlertFirstButtonReturn) {
        if (!accessibility)
            [self openAccessibilitySettings];
        else
            [self openInputMonitoringSettings];
    }

    return NO;
}

@end
