#import <Foundation/Foundation.h>

@interface NJPermissions : NSObject

+ (BOOL)hasAccessibilityPermission;
+ (BOOL)requestAccessibilityPermission;

+ (BOOL)hasInputMonitoringPermission;
+ (BOOL)requestInputMonitoringPermission;

/// Returns NO if any required permission is missing after prompting.
+ (BOOL)ensureRequiredPermissionsWithPrompt:(BOOL)prompt;

+ (void)openAccessibilitySettings;
+ (void)openInputMonitoringSettings;

@end
