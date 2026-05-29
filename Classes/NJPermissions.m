#import "NJPermissions.h"

#import <ApplicationServices/ApplicationServices.h>
#import <AppKit/AppKit.h>

@implementation NJPermissions

+ (BOOL)hasAccessibilityPermission {
    return AXIsProcessTrusted();
}

+ (BOOL)hasInputMonitoringPermission {
    if (@available(macOS 10.15, *))
        return CGPreflightListenEventAccess();
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

+ (BOOL)ensureAccessibilityForSimulation {
    if ([self hasAccessibilityPermission])
        return YES;

    NSString *message = NSLocalizedString(
        @"Enjoyable needs Accessibility permission to simulate keyboard input.\n\n"
        @"Open System Settings → Privacy & Security → Accessibility, "
        @"enable Enjoyable, then quit (⌘Q) and reopen.\n\n"
        @"If Enjoyable is already listed but mapping still fails, remove it "
        @"from the list with −, add it again with +, then restart. "
        @"This is often needed after reinstalling the app.",
        @"Accessibility permission alert message");

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(
        @"Accessibility Permission Required",
        @"Accessibility permission alert title");
    alert.informativeText = message;
    [alert addButtonWithTitle:NSLocalizedString(@"Open Settings", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Later", nil)];

    if ([alert runModal] == NSAlertFirstButtonReturn)
        [self openAccessibilitySettings];

    return NO;
}

+ (BOOL)ensureRequiredPermissionsWithPrompt:(BOOL)prompt {
    if ([self hasAccessibilityPermission])
        return YES;
    if (!prompt)
        return NO;
    return [self ensureAccessibilityForSimulation];
}

@end
