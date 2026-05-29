#import <Foundation/Foundation.h>

@interface NJPermissions : NSObject

+ (BOOL)hasAccessibilityPermission;
+ (BOOL)hasInputMonitoringPermission;

/// Accessibility is required to simulate keyboard input.
+ (BOOL)ensureAccessibilityForSimulation;

/// Returns NO if Accessibility is missing. Does not call system TCC prompt APIs.
+ (BOOL)ensureRequiredPermissionsWithPrompt:(BOOL)prompt;

+ (void)openAccessibilitySettings;
+ (void)openInputMonitoringSettings;

@end
