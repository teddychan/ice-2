// Standalone macOS 27 compatibility experiment. See docs/testing/macos27-prototype.md.
// The private API names were researched using Pelmet's documented implementation:
// https://github.com/fif7y/pelmet (GPL-3.0). No production Ice backend is changed.
#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <dlfcn.h>
#import <objc/message.h>

static id Attribute(AXUIElementRef element, CFStringRef name) {
    CFTypeRef value = NULL;
    if (AXUIElementCopyAttributeValue(element, name, &value) != kAXErrorSuccess) return nil;
    return CFBridgingRelease(value);
}

static NSArray *Children(AXUIElementRef element) {
    id children = Attribute(element, kAXChildrenAttribute);
    return [children isKindOfClass:NSArray.class] ? children : @[];
}

// Keep groups separate, including repeated items owned by the same app and copies
// on different displays. These are observations, not stable profile identifiers.
static void Describe(AXUIElementRef element, pid_t agentPID, NSUInteger depth,
                     NSMutableSet<NSString *> *owners, NSMutableSet<NSString *> *labels) {
    if (depth > 4) return;
    pid_t pid = 0;
    AXUIElementGetPid(element, &pid);
    NSString *bundle = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].bundleIdentifier;
    if (pid != agentPID && bundle) [owners addObject:bundle];
    for (NSString *key in @[@"AXTitle", @"AXIdentifier", @"AXDescription"]) {
        id value = Attribute(element, (__bridge CFStringRef)key);
        if ([value isKindOfClass:NSString.class] && [value length]) [labels addObject:value];
    }
    // Hosted applications expose their ordinary menus too; don't enumerate them.
    if ([Attribute(element, kAXRoleAttribute) isEqual:@"AXApplication"]) return;
    for (id child in Children(element)) {
        Describe((__bridge AXUIElementRef)child, agentPID, depth + 1, owners, labels);
    }
}

static NSArray<NSDictionary *> *Snapshot(void) {
    NSRunningApplication *agent = [NSRunningApplication
        runningApplicationsWithBundleIdentifier:@"com.apple.MenuBarAgent"].firstObject;
    if (!agent || !AXIsProcessTrusted()) return nil;
    AXUIElementRef root = AXUIElementCreateApplication(agent.processIdentifier);
    AXUIElementSetMessagingTimeout(root, 0.3);
    NSMutableArray *items = [NSMutableArray array];
    NSUInteger displayIndex = 0;
    for (id window in Children(root)) {
        AXUIElementRef windowElement = (__bridge AXUIElementRef)window;
        if (![Attribute(windowElement, kAXRoleAttribute) isEqual:@"AXWindow"]) continue;
        for (id group in Children(windowElement)) {
            AXUIElementRef element = (__bridge AXUIElementRef)group;
            id value = Attribute(element, CFSTR("AXFrame"));
            CGRect frame = CGRectZero;
            if (!value || CFGetTypeID((__bridge CFTypeRef)value) != AXValueGetTypeID() ||
                !AXValueGetValue((__bridge AXValueRef)value, kAXValueCGRectType, &frame)) continue;
            NSMutableSet *owners = [NSMutableSet set];
            NSMutableSet *labels = [NSMutableSet set];
            Describe(element, agent.processIdentifier, 0, owners, labels);
            [items addObject:@{
                @"displayIndex": @(displayIndex),
                @"owners": [[owners allObjects] sortedArrayUsingSelector:@selector(compare:)],
                @"labels": [[labels allObjects] sortedArrayUsingSelector:@selector(compare:)],
                @"frame": NSStringFromRect(frame)
            }];
        }
        displayIndex++;
    }
    CFRelease(root);
    return items;
}

static void Report(NSString *stage, NSArray *items) {
    NSDictionary *report = @{@"stage": stage, @"axTrusted": @(AXIsProcessTrusted()), @"items": items ?: @[]};
    NSData *data = [NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:NULL];
    puts([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding].UTF8String);
    fflush(stdout);
}

static NSUInteger ProbeOccurrences(NSArray<NSDictionary *> *items, NSString *bundle) {
    NSUInteger count = 0;
    for (NSDictionary *item in items) {
        if ([item[@"owners"] containsObject:bundle]) count++;
    }
    return count;
}

static void Pump(NSTimeInterval seconds) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:seconds];
    while ([deadline timeIntervalSinceNow] > 0) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    }
}

@interface PrototypeController : NSObject <NSApplicationDelegate>
@property NSWindow *window;
@property NSPopUpButton *targets;
@property NSTextField *message;
@property NSStatusItem *statusItem;
@property id assertion;
@end

@implementation PrototypeController
- (void)restore {
    if (self.assertion) {
        ((void (*)(id, SEL))objc_msgSend)(self.assertion, NSSelectorFromString(@"invalidate"));
        self.assertion = nil;
    }
}
- (void)showAll:(id)sender {
    (void)sender;
    [self restore];
    self.message.stringValue = @"Restored. Choose an app, then click Hide Selected.";
}
- (void)hideSelected:(id)sender {
    (void)sender;
    [self restore];
    NSString *target = self.targets.selectedItem.representedObject;
    if (!target) return;
    NSMutableSet *allowed = [NSMutableSet set];
    for (NSRunningApplication *app in NSWorkspace.sharedWorkspace.runningApplications) {
        if (app.bundleIdentifier && ![app.bundleIdentifier isEqual:target]) [allowed addObject:app.bundleIdentifier];
    }
    @try {
        Class configClass = NSClassFromString(@"MBAssessmentModeConfiguration");
        id configuration = ((id (*)(id, SEL, id, id))objc_msgSend)([configClass alloc],
            NSSelectorFromString(@"initWithAllowedSystemItems:allowedBundleIdentifiers:"),
            @[@0, @1, @2, @3, @4, @5, @6, @7, @8], allowed.allObjects);
        self.assertion = [[NSClassFromString(@"MBAssessmentModeAssertion") alloc] init];
        if (!configuration || !self.assertion) {
            [self restore];
            self.message.stringValue = @"Native hiding is unavailable.";
            return;
        }
        id currentAssertion = self.assertion;
        self.message.stringValue = @"Requesting hide…";
        ((void (*)(id, SEL, id, void (^)(NSError *)))objc_msgSend)(self.assertion,
            NSSelectorFromString(@"activateWithConfiguration:completionHandler:"), configuration,
            ^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.assertion != currentAssertion) return;
                    if (error) {
                        [self restore];
                        self.message.stringValue = error.localizedDescription;
                    } else {
                        self.message.stringValue = @"Hide request accepted. Check the menu bar; Show All restores it.";
                    }
                });
            });
    } @catch (NSException *exception) {
        [self restore];
        self.message.stringValue = exception.reason ?: @"Native API failed.";
    }
}
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title = @"I27";
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 570, 240)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
        backing:NSBackingStoreBuffered defer:NO];
    self.window.releasedWhenClosed = NO;
    self.window.title = @"Ice 2 — macOS 27 Prototype";
    NSTextField *intro = [NSTextField wrappingLabelWithString:
        @"Choose an app to test native menu bar hiding. Start with the disposable I27 icon.\nFocus and some system extras may also hide temporarily. Quitting restores the bar."];
    intro.frame = NSMakeRect(20, 153, 530, 67);
    [self.window.contentView addSubview:intro];
    self.targets = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(20, 109, 530, 30) pullsDown:NO];
    [self.targets addItemWithTitle:@"I27 — disposable test icon"];
    self.targets.lastItem.representedObject = NSBundle.mainBundle.bundleIdentifier;
    NSMutableSet *bundles = [NSMutableSet set];
    for (NSDictionary *item in Snapshot()) [bundles addObjectsFromArray:item[@"owners"]];
    for (NSString *bundle in [[bundles allObjects] sortedArrayUsingSelector:@selector(compare:)]) {
        if ([bundle hasPrefix:@"com.apple."] || [bundle isEqual:NSBundle.mainBundle.bundleIdentifier]) continue;
        [self.targets addItemWithTitle:bundle];
        self.targets.lastItem.representedObject = bundle;
    }
    [self.window.contentView addSubview:self.targets];
    NSArray *titles = @[@"Hide Selected", @"Show All", @"Quit"];
    NSArray *actions = @[@"hideSelected:", @"showAll:", @"terminate:"];
    for (NSUInteger index = 0; index < titles.count; index++) {
        NSButton *button = [NSButton buttonWithTitle:titles[index] target:index == 2 ? NSApp : self
            action:NSSelectorFromString(actions[index])];
        button.frame = NSMakeRect(20 + index * 180, 64, 170, 32);
        [self.window.contentView addSubview:button];
    }
    self.message = [NSTextField wrappingLabelWithString:AXIsProcessTrusted()
        ? @"Ready. Nothing is hidden yet."
        : @"I27 test ready. Other app discovery needs Accessibility permission; grant it and relaunch."];
    self.message.frame = NSMakeRect(20, 14, 530, 42);
    [self.window.contentView addSubview:self.message];
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    (void)sender;
    return YES;
}
- (void)applicationWillTerminate:(NSNotification *)notification {
    (void)notification;
    [self restore];
    if (self.statusItem) [NSStatusBar.systemStatusBar removeStatusItem:self.statusItem];
}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        BOOL selfTest = argc == 2 && strcmp(argv[1], "--self-test") == 0;
        if (argc > 1 && !selfTest) {
            fprintf(stderr, "Usage: macos27-prototype [--self-test]\n");
            return 2;
        }
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        printf("OS: %s\n", NSProcessInfo.processInfo.operatingSystemVersionString.UTF8String);
        if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < 27) return 2;
        void *framework = dlopen("/System/Library/PrivateFrameworks/MenuBarClientCore.framework/MenuBarClientCore", RTLD_LAZY);
        Class configClass = NSClassFromString(@"MBAssessmentModeConfiguration");
        Class assertionClass = NSClassFromString(@"MBAssessmentModeAssertion");
        SEL configure = NSSelectorFromString(@"initWithAllowedSystemItems:allowedBundleIdentifiers:");
        SEL activate = NSSelectorFromString(@"activateWithConfiguration:completionHandler:");
        SEL invalidate = NSSelectorFromString(@"invalidate");
        BOOL available = framework && [configClass instancesRespondToSelector:configure] &&
            [assertionClass instancesRespondToSelector:activate] && [assertionClass instancesRespondToSelector:invalidate];
        printf("Native hiding selectors available: %s\n", available ? "yes" : "no");
        Report(@"discovery", Snapshot());
        NSString *bundle = NSBundle.mainBundle.bundleIdentifier;
        if (!selfTest && available && [bundle isEqual:@"com.dragonapp.ice.macos27-prototype"]) {
            [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
            PrototypeController *controller = [PrototypeController new];
            NSApp.delegate = controller;
            [NSApp run];
            return 0;
        }
        if (!selfTest) return available && AXIsProcessTrusted() ? 0 : 2;
        if (!available || !AXIsProcessTrusted() || ![bundle isEqual:@"com.dragonapp.ice.macos27-prototype"]) {
            fprintf(stderr, "Self-test needs the prototype app bundle, native selectors and Accessibility permission.\n");
            return 2;
        }

        // Hide only our disposable item. Do not move icons or write preferences.
        NSStatusItem *statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
        statusItem.button.title = @"I27";
        statusItem.button.accessibilityLabel = @"Ice 2 macOS 27 probe";
        Pump(2);
        NSArray *before = Snapshot();
        Report(@"before", before);
        NSUInteger originalOccurrences = ProbeOccurrences(before, bundle);
        if (!originalOccurrences) {
            fprintf(stderr, "Probe item is absent from AX; refusing an unverifiable hide test.\n");
            [NSStatusBar.systemStatusBar removeStatusItem:statusItem];
            return 2;
        }
        NSMutableSet *allowed = [NSMutableSet set];
        for (NSRunningApplication *app in NSWorkspace.sharedWorkspace.runningApplications) {
            if (app.bundleIdentifier && ![app.bundleIdentifier isEqual:bundle]) [allowed addObject:app.bundleIdentifier];
        }
        // Preserve the known native system-item identifiers. Some additional
        // Control Center modules may nevertheless disappear during assessment.
        NSArray *systemItems = @[@0, @1, @2, @3, @4, @5, @6, @7, @8];
        __block BOOL completed = NO;
        __block NSError *activationError = nil;
        id assertion = nil;
        BOOL hidden = NO;
        @try {
            id (*makeConfig)(id, SEL, id, id) = (void *)objc_msgSend;
            id configuration = makeConfig([configClass alloc], configure, systemItems, allowed.allObjects);
            assertion = [[assertionClass alloc] init];
            if (!configuration || !assertion) @throw [NSException exceptionWithName:@"Unavailable" reason:@"Could not construct assertion" userInfo:nil];
            void (*activateAssertion)(id, SEL, id, void (^)(NSError *)) = (void *)objc_msgSend;
            activateAssertion(assertion, activate, configuration, ^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    activationError = error;
                    completed = YES;
                });
            });
            // Bounded assertion lifetime even when activation never calls back.
            Pump(3);
            NSArray *during = Snapshot();
            Report(@"during", during);
            hidden = during.count > 0 && ProbeOccurrences(during, bundle) == 0;
            printf("Activation completed: %s; error: %s; probe hidden: %s\n",
                   completed ? "yes" : "no", activationError.description.UTF8String ?: "none", hidden ? "yes" : "no");
        } @catch (NSException *exception) {
            fprintf(stderr, "Native API exception: %s\n", exception.description.UTF8String);
        } @finally {
            if (assertion) {
                void (*releaseAssertion)(id, SEL) = (void *)objc_msgSend;
                releaseAssertion(assertion, invalidate);
            }
        }
        Pump(2);
        NSArray *after = Snapshot();
        Report(@"after", after);
        BOOL restored = ProbeOccurrences(after, bundle) == originalOccurrences;
        [NSStatusBar.systemStatusBar removeStatusItem:statusItem];
        BOOL passed = completed && !activationError && hidden && restored;
        printf("SELF-TEST: %s (hide=%s restore=%s)\n", passed ? "PASS" : "FAIL",
               hidden ? "yes" : "no", restored ? "yes" : "no");
        return passed ? 0 : 1;
    }
}
