//
//  EnjoyableApplicationDelegate.m
//  Enjoy
//
//  Created by Sam McCall on 4/05/09.
//

#import "EnjoyableApplicationDelegate.h"

#import "NJMapping.h"
#import "NJInput.h"
#import "NJEvents.h"
#import "NJPermissions.h"

@implementation EnjoyableApplicationDelegate {
    NSStatusItem *statusItem;
    NSMutableArray *_errors;
}

static NSString * const kSimulationToolbarItemID =
    @"2CB21E35-9CF1-4C67-9670-31139C914D10";
static NSString * const kToolbarLayoutVersionKey =
    @"com.yukkurigames.Enjoyable.simulationToolbarLayoutVersion";
static NSString * const kToolbarLayoutVersion = @"3";

- (void)didSwitchApplication:(NSNotification *)note {
    NSRunningApplication *activeApp = note.userInfo[NSWorkspaceApplicationKey];
    if (activeApp)
        [self.ic activateMappingForProcess:activeApp];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [NSNotificationCenter.defaultCenter
        addObserver:self
        selector:@selector(mappingDidChange:)
        name:NJEventMappingChanged
        object:nil];
    [NSNotificationCenter.defaultCenter
        addObserver:self
        selector:@selector(eventSimulationStarted:)
        name:NJEventSimulationStarted
        object:nil];
    [NSNotificationCenter.defaultCenter
        addObserver:self
        selector:@selector(eventSimulationStopped:)
        name:NJEventSimulationStopped
        object:nil];

    [self.ic load];
    [self.mvc.mappingList reloadData];
    [self.mvc changedActiveMappingToIndex:
     [self.ic indexOfMapping:
      self.ic.currentMapping]];

    statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:36];
    statusItem.image = [NSImage imageNamed:@"Status Menu Icon Disabled"];
    statusItem.highlightMode = YES;
    statusItem.menu = self.statusItemMenu;
    statusItem.target = self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"hidden in status item"]
        && NSRunningApplication.currentApplication.wasLaunchedAsLoginItemOrResume)
        [self transformIntoElement:nil];
    else
        [self.window makeKeyAndOrderFront:nil];

    [self performSelector:@selector(checkPermissionsOnLaunch)
               withObject:nil
               afterDelay:0.5];

    [self performSelector:@selector(configureSimulatingEventsButton)
               withObject:nil
               afterDelay:0.1];
    [self performSelector:@selector(configureSimulatingEventsButton)
               withObject:nil
               afterDelay:0.5];
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    [self configureSimulatingEventsButton];
}

- (void)resetSimulationToolbarLayoutIfNeeded {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([[defaults stringForKey:kToolbarLayoutVersionKey] isEqualToString:kToolbarLayoutVersion])
        return;

    NSToolbar *toolbar = self.window.toolbar;
    if (toolbar.identifier.length) {
        NSString *configKey = [NSString stringWithFormat:@"NSToolbar Configuration %@",
                               toolbar.identifier];
        [defaults removeObjectForKey:configKey];
    }

    [defaults setObject:kToolbarLayoutVersion forKey:kToolbarLayoutVersionKey];
}

- (NSImage *)simulationButtonImageRunning:(BOOL)running {
    NSString *label = running
        ? NSLocalizedString(@"Stop", @"toolbar button to stop mapping")
        : NSLocalizedString(@"Start", @"toolbar button to start mapping");
    NSString *title = running
        ? [NSString stringWithFormat:@"■ %@", label]
        : [NSString stringWithFormat:@"▶ %@", label];
    NSColor *textColor = running
        ? NSColor.systemRedColor
        : [NSColor colorWithCalibratedRed:0.08 green:0.45 blue:0.18 alpha:1.0];
    NSFont *font = [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold];
    NSDictionary *attrs = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: textColor,
    };

    NSSize textSize = [title sizeWithAttributes:attrs];
    CGFloat padX = 12.0;
    NSSize size = NSMakeSize(MAX(textSize.width + padX * 2, 80), 24);

    return [NSImage imageWithSize:size flipped:NO drawingHandler:^BOOL(NSRect rect) {
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 0.5, 0.5)
                                                             xRadius:rect.size.height / 2.0
                                                             yRadius:rect.size.height / 2.0];
        [NSColor.controlBackgroundColor setFill];
        [path fill];
        [NSColor.separatorColor setStroke];
        [path setLineWidth:1.0];
        [path stroke];
        NSPoint point = NSMakePoint(padX, floor((rect.size.height - textSize.height) / 2.0));
        [title drawAtPoint:point withAttributes:attrs];
        return YES;
    }];
}

- (void)updateSimulatingEventsButtonAppearance {
    NSButton *button = self.simulatingEventsButton;
    if (!button)
        return;

    BOOL running = self.ic.simulatingEvents;
    button.toolTip = running
        ? NSLocalizedString(@"stop mapping tooltip", @"tooltip when mapping is on")
        : NSLocalizedString(@"start mapping tooltip", @"tooltip when mapping is off");

    button.title = @"";
    button.alternateTitle = @"";
    button.attributedTitle = nil;
    button.contentTintColor = nil;
    button.imagePosition = NSImageOnly;
    button.image = [self simulationButtonImageRunning:running];
    button.alternateImage = nil;

    NSSize imageSize = button.image.size;
    NSRect frame = button.frame;
    frame.size.width = imageSize.width + 4;
    frame.size.height = MAX(imageSize.height + 2, 25);
    button.frame = frame;
    [button setNeedsDisplay:YES];
}

- (void)configureSimulatingEventsButton {
    NSButton *button = self.simulatingEventsButton;
    if (!button)
        return;

    [self resetSimulationToolbarLayoutIfNeeded];

    [button setButtonType:NSButtonTypeMomentaryPushIn];
    button.bezelStyle = NSBezelStyleShadowlessSquare;
    button.bordered = NO;
    button.imagePosition = NSImageOnly;
    button.title = @"";

    NSToolbar *toolbar = self.window.toolbar;
    NSToolbarItem *item = nil;
    if (toolbar) {
        for (NSToolbarItem *candidate in toolbar.items) {
            if ([candidate.itemIdentifier isEqualToString:kSimulationToolbarItemID]
                || candidate.view == button) {
                item = candidate;
                break;
            }
        }
    }
    if (item) {
        item.image = nil;
        item.label = @"";
    }

    [self updateSimulatingEventsButtonAppearance];

    if (item) {
        NSSize imageSize = button.image.size;
        CGFloat width = MAX(imageSize.width + 8, 88);
        item.minSize = NSMakeSize(width, 25);
        item.maxSize = NSMakeSize(width + 24, 25);
        if (item.view) {
            NSRect frame = item.view.frame;
            frame.size.width = width;
            frame.size.height = 25;
            item.view.frame = frame;
        }
        [toolbar validateVisibleItems];
    }
}

- (void)checkPermissionsOnLaunch {
    // Do not call system TCC prompt APIs on launch — ad-hoc resign after
    // reinstall often invalidates cached grants until the user re-adds the app.
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication
                    hasVisibleWindows:(BOOL)flag {
    [self restoreToForeground:theApplication];
    return NO;
}

- (void)restoreToForeground:(id)sender {
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    [NSApplication.sharedApplication activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront:sender];
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(transformIntoElement:)
                                               object:self];
    [NSUserDefaults.standardUserDefaults setBool:NO forKey:@"hidden in status item"];
}

- (void)applicationWillBecomeActive:(NSNotification *)notification {
    if (self.window.isVisible)
        [self restoreToForeground:notification];
}

- (void)transformIntoElement:(id)sender {
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToUIElementApplication);
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"hidden in status item"];
}

- (void)flashStatusItem {
    if ([statusItem.image.name isEqualToString:@"Status Menu Icon"]) {
        statusItem.image = [NSImage imageNamed:@"Status Menu Icon Disabled"];
    } else {
        statusItem.image = [NSImage imageNamed:@"Status Menu Icon"];
    }
    
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    [theApplication hide:theApplication];
    // If we turn into a UIElement right away, the application cancels
    // the deactivation events. The dock icon disappears, but an
    // unresponsive menu bar remains until the user clicks somewhere.
    // So delay just long enough to be past the end handling that.
    [self performSelector:@selector(transformIntoElement:) withObject:self afterDelay:0.001];
    return NO;
}

- (void)eventSimulationStarted:(NSNotification *)note {
    [self updateSimulatingEventsButtonAppearance];
    statusItem.image = [NSImage imageNamed:@"Status Menu Icon"];
    [NSProcessInfo.processInfo
        disableAutomaticTermination:@"Event simulation running."];
    [NSWorkspace.sharedWorkspace.notificationCenter
        addObserver:self
        selector:@selector(didSwitchApplication:)
        name:NSWorkspaceDidActivateApplicationNotification
        object:nil];
}

- (void)eventSimulationStopped:(NSNotification *)note {
    [self updateSimulatingEventsButtonAppearance];
    statusItem.image = [NSImage imageNamed:@"Status Menu Icon Disabled"];
    [NSProcessInfo.processInfo
        enableAutomaticTermination:@"Event simulation running."];
    [NSWorkspace.sharedWorkspace.notificationCenter
        removeObserver:self
        name:NSWorkspaceDidActivateApplicationNotification
        object:nil];
}

- (void)mappingDidChange:(NSNotification *)note {
    NSUInteger idx = [note.userInfo[NJMappingIndexKey] intValue];
    [self.mvc changedActiveMappingToIndex:idx];

    if (!self.window.isVisible)
        for (int i = 0; i < 4; ++i)
            [self performSelector:@selector(flashStatusItem)
                       withObject:self
                       afterDelay:0.2 * i];
    [self loadOutputForInput:self.dvc.selectedHandler];
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender {
    return self.dockMenu;
}

- (void)showNextError {
    if (!self.window.attachedSheet && _errors.count) {
        NSError *error = _errors.lastObject;
        [_errors removeLastObject];
        [NSApplication.sharedApplication activateIgnoringOtherApps:YES];
        [self.window makeKeyAndOrderFront:nil];
        [self.window presentError:error
                   modalForWindow:self.window
                         delegate:self
               didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:)
                      contextInfo:nil];
    }
}

- (void)didPresentErrorWithRecovery:(BOOL)didRecover
                        contextInfo:(void *)contextInfo {
    [self showNextError];
}

- (void)presentErrorSheet:(NSError *)error {
    if (!_errors)
        _errors = [[NSMutableArray alloc] initWithCapacity:1];
    [_errors insertObject:error atIndex:0];
    [self showNextError];
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    [self restoreToForeground:sender];
    NSError *error;
    NSURL *URL = [NSURL fileURLWithPath:filename];
    NJMapping *mapping = [NJMapping mappingWithContentsOfURL:URL
                                                       error:&error];
    if ([[self.ic mappingForKey:mapping.name] hasConflictWith:mapping]) {
        [self promptForMapping:mapping atIndex:self.ic.mappings.count];
    } else if ([self.ic  mappingForKey:mapping.name]) {
        [[self.ic mappingForKey:mapping.name] mergeEntriesFrom:mapping];
    } else if (mapping) {
        [self.mvc beginUpdates];
        [self.ic addMapping:mapping];
        [self.mvc addedMappingAtIndex:self.ic.mappings.count - 1 startEditing:NO];
        [self.mvc endUpdates];
        [self.ic activateMapping:mapping];
    } else {
        [self presentErrorSheet:error];
    }
    return !!mapping;
}

- (void)mappingWasChosen:(NJMapping *)mapping {
    [self.ic activateMapping:mapping];
}

- (void)mappingListShouldOpen {
    [self restoreToForeground:self];
    [self.mvc mappingTriggerClicked:self];
}

- (void)importMappingClicked:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[ @"enjoyable", @"json", @"txt" ];
    [panel beginSheetModalForWindow:self.window
                  completionHandler:^(NSInteger result) {
                      if (result != NSFileHandlingPanelOKButton)
                          return;
                      [panel close];
                      NSError *error;
                      NJMapping *mapping = [NJMapping mappingWithContentsOfURL:panel.URL
                                                                         error:&error];
                      if ([[self.ic mappingForKey:mapping.name] hasConflictWith:mapping]) {
                          [self promptForMapping:mapping atIndex:self.ic.mappings.count];
                      } else if ([self.ic mappingForKey:mapping.name]) {
                          [[self.ic mappingForKey:mapping.name] mergeEntriesFrom:mapping];
                      } else if (mapping) {
                          [self.ic addMapping:mapping];
                      } else {
                          [self presentErrorSheet:error];
                      }
                  }];
    
}

- (void)exportMappingClicked:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.allowedFileTypes = @[ @"enjoyable" ];
    NJMapping *mapping = self.ic.currentMapping;
    panel.nameFieldStringValue = [mapping.name stringByFixingPathComponent];
    [panel beginSheetModalForWindow:self.window
                  completionHandler:^(NSInteger result) {
                      if (result != NSFileHandlingPanelOKButton)
                          return;
                      [panel close];
                      NSError *error;
                      if (![mapping writeToURL:panel.URL error:&error]) {
                          [self presentErrorSheet:error];
                      }
                  }];
}

- (void)mappingConflictDidResolve:(NSAlert *)alert
                       returnCode:(NSInteger)returnCode
                      contextInfo:(void *)contextInfo {
    NSDictionary *userInfo = CFBridgingRelease(contextInfo);
    NJMapping *oldMapping = userInfo[@"old mapping"];
    NJMapping *newMapping = userInfo[@"new mapping"];
    NSInteger idx = [userInfo[@"index"] intValue];
    [alert.window orderOut:nil];
    switch (returnCode) {
        case NSAlertFirstButtonReturn: // Merge
            [self.ic mergeMapping:newMapping intoMapping:oldMapping];
            [self.ic activateMapping:oldMapping];
            break;
        case NSAlertThirdButtonReturn: // New Mapping
            [self.mvc beginUpdates];
            [self.ic addMapping:newMapping];
            [self.mvc addedMappingAtIndex:idx startEditing:YES];
            [self.mvc endUpdates];
            [self.ic activateMapping:newMapping];
            break;
        default: // Cancel, other.
            break;
    }
}

- (void)promptForMapping:(NJMapping *)mapping atIndex:(NSInteger)idx {
    NJMapping *mergeInto = [self.ic mappingForKey:mapping.name];
    NSAlert *conflictAlert = [[NSAlert alloc] init];
    conflictAlert.messageText = NSLocalizedString(@"import conflict prompt", @"Title of import conflict alert");
    conflictAlert.informativeText =
    [NSString stringWithFormat:NSLocalizedString(@"import conflict in %@", @"Explanation of import conflict"),
     mapping.name];
    [conflictAlert addButtonWithTitle:NSLocalizedString(@"import and merge", @"button to merge imported mappings")];
    [conflictAlert addButtonWithTitle:NSLocalizedString(@"cancel import", @"button to cancel import")];
    [conflictAlert addButtonWithTitle:NSLocalizedString(@"import new mapping", @"button to import as new mapping")];
    [conflictAlert beginSheetModalForWindow:self.window
                              modalDelegate:self
                             didEndSelector:@selector(mappingConflictDidResolve:returnCode:contextInfo:)
                                contextInfo:(void *)CFBridgingRetain(@{ @"index": @(idx),
                                                                        @"old mapping": mergeInto,
                                                                        @"new mapping": mapping })];
}

- (NSInteger)numberOfMappings:(NJMappingsViewController *)mvc {
    return self.ic.mappings.count;
}

- (NJMapping *)mappingsViewController:(NJMappingsViewController *)mvc
                      mappingForIndex:(NSUInteger)idx {
    return self.ic.mappings[idx];
}

- (void)mappingsViewController:(NJMappingsViewController *)mvc
          renameMappingAtIndex:(NSInteger)index
                        toName:(NSString *)name {
    [self.ic renameMapping:self.ic.mappings[index] to:name];
}

- (BOOL)mappingsViewController:(NJMappingsViewController *)mvc
       canMoveMappingFromIndex:(NSInteger)fromIdx
                       toIndex:(NSInteger)toIdx {
    return fromIdx != toIdx && fromIdx != 0 && toIdx != 0
            && toIdx < (NSInteger)self.ic.mappings.count;
}

- (void)mappingsViewController:(NJMappingsViewController *)mvc
          moveMappingFromIndex:(NSInteger)fromIdx
                       toIndex:(NSInteger)toIdx {
    [mvc beginUpdates];
    [mvc.mappingList moveRowAtIndex:fromIdx toIndex:toIdx];
    [self.ic moveMoveMappingFromIndex:fromIdx toIndex:toIdx];
    [mvc endUpdates];
}

- (BOOL)mappingsViewController:(NJMappingsViewController *)mvc
       canRemoveMappingAtIndex:(NSInteger)idx {
    return idx != 0;
}

- (void)mappingsViewController:(NJMappingsViewController *)mvc
          removeMappingAtIndex:(NSInteger)idx {
    [mvc beginUpdates];
    [mvc removedMappingAtIndex:idx];
    [self.ic removeMappingAtIndex:idx];
    [mvc endUpdates];
}

- (BOOL)mappingsViewController:(NJMappingsViewController *)mvc
          importMappingFromURL:(NSURL *)url
                       atIndex:(NSInteger)index
                         error:(NSError **)error {
    NJMapping *mapping = [NJMapping mappingWithContentsOfURL:url
                                                       error:error];
    if ([[self.ic mappingForKey:mapping.name] hasConflictWith:mapping]) {
        [self promptForMapping:mapping atIndex:index];
    } else if ([self.ic mappingForKey:mapping.name]) {
        [[self.ic mappingForKey:mapping.name] mergeEntriesFrom:mapping];
    } else if (mapping) {
        [self.mvc beginUpdates];
        [self.mvc addedMappingAtIndex:index startEditing:NO];
        [self.ic insertMapping:mapping atIndex:index];
        [self.mvc endUpdates];
    }
    return !!mapping;
}

- (void)mappingsViewController:(NJMappingsViewController *)mvc
                    addMapping:(NJMapping *)mapping {
    [mvc beginUpdates];
    [mvc addedMappingAtIndex:self.ic.mappings.count startEditing:YES];
    [self.ic addMapping:mapping];
    [mvc endUpdates];
    [self.ic activateMapping:mapping];
}

- (void)mappingsViewController:(NJMappingsViewController *)mvc
           choseMappingAtIndex:(NSInteger)idx {
    [self.ic activateMapping:self.ic.mappings[idx]];
}

- (id)deviceViewController:(NJDeviceViewController *)dvc
             elementForUID:(NSString *)uid {
    return [self.ic elementForUID:uid];
}

- (void)loadOutputForInput:(NJInput *)input {
    NJOutput *output = self.ic.currentMapping[input];
    [self.oc loadOutput:output forInput:input];
}

- (void)deviceViewControllerDidSelectNothing:(NJDeviceViewController *)dvc {
    [self loadOutputForInput:nil];
}

- (void)deviceViewController:(NJDeviceViewController *)dvc
             didSelectBranch:(NJInputPathElement *)handler {
    [self loadOutputForInput:dvc.selectedHandler];
}

- (void)deviceViewController:(NJDeviceViewController *)dvc
            didSelectHandler:(NJInputPathElement *)handler {
    [self loadOutputForInput:dvc.selectedHandler];
}

- (void)deviceViewController:(NJDeviceViewController *)dvc
             didSelectDevice:(NJInputPathElement *)device {
    [self loadOutputForInput:dvc.selectedHandler];
}

- (void)inputController:(NJInputController *)ic
           didAddDevice:(NJDevice *)device {
    [self.dvc addedDevice:device atIndex:ic.devices.count - 1];
}

- (void)inputController:(NJInputController *)ic
 didRemoveDeviceAtIndex:(NSInteger)idx {
    [self.dvc removedDeviceAtIndex:idx];
}

- (void)inputControllerDidStartHID:(NJInputController *)ic {
    [self.dvc hidStarted];
}

- (void)inputControllerDidStopHID:(NJInputController *)ic {
    [self.dvc hidStopped];
}

- (void)inputController:(NJInputController *)ic didInput:(NJInput *)input {
    [self.dvc expandAndSelectItem:input];
    [self loadOutputForInput:input];
    [self.oc focusKey];
}

- (void)inputController:(NJInputController *)ic didError:(NSError *)error {
    [self presentErrorSheet:error];
}

- (NSInteger)numberOfDevicesInDeviceList:(NJDeviceViewController *)dvc {
    return self.ic.devices.count;
}

- (NJDevice *)deviceViewController:(NJDeviceViewController *)dvc
                    deviceForIndex:(NSUInteger)idx {
    return self.ic.devices[idx];
}

- (IBAction)simulatingEventsChanged:(id)sender {
    BOOL wantOn = !self.ic.simulatingEvents;
    if (wantOn) {
        if (![NJPermissions ensureRequiredPermissionsWithPrompt:YES]) {
            [self updateSimulatingEventsButtonAppearance];
            return;
        }
    }
    self.ic.simulatingEvents = wantOn;
    [self updateSimulatingEventsButtonAppearance];
}

- (void)outputViewController:(NJOutputViewController *)ovc
                   setOutput:(NJOutput *)output
                    forInput:(NJInput *)input {
    self.ic.currentMapping[input] = output;
    [self.ic save];
}

- (NJMapping *)outputViewController:(NJOutputViewController *)ovc
                    mappingForIndex:(NSUInteger)index {
    return self.ic.mappings[index];
}

@end
