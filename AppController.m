#import <Carbon/Carbon.h>
#import "AppController.h"
#import "PathExtra/PathExtra.h"
#import "NSUserDefaultsExtensions.h"
#import "DropBox/DropBox.h"
#import "PreferencesWindowController.h"
#import "MonitorWindowController.h"

#define useLog 0

#ifndef SANDBOX
#define SANDBOX 0
#endif

#if !SANDBOX
#import "Sparkle/SUUpdater.h"
#import "DonationReminder/DonationReminder.h"
#endif

@interface IsCSSGenerateTransformer : NSValueTransformer
{}
@end

@implementation IsCSSGenerateTransformer

+ (Class)transformedValueClass
{
	return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	
	id css_mode_index = [[NSUserDefaultsController sharedUserDefaultsController] 
						 valueForKeyPath:@"values.CSSModeIndex"];
	
	return [NSNumber numberWithBool:([css_mode_index intValue] != 2)];
}

@end

@implementation AppController

+ (void)initialize
{	
	NSValueTransformer *transformer = [[IsCSSGenerateTransformer alloc] init];
	[NSValueTransformer setValueTransformer:transformer forName:@"IsCSSGenerateTransformer"];
}

#pragma mark services for scripts

//MARK: private methods

- (BOOL)updateTargetScriptURL:(NSURL *)an_url
{
    NSError *error = nil;
    NSData *bmdata = [an_url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                      includingResourceValuesForKeys:nil
                                       relativeToURL:nil
                                               error:&error];
    NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
    [[NSUserDefaultsController sharedUserDefaultsController]
					setValue:an_url.path forKeyPath:@"values.TargetScript"];
    [user_defaults setObject:bmdata forKey:@"TargetScriptBookmark"];
    [user_defaults setObject:@0 forKey:@"TargetMode"];
    [user_defaults addToHistory:bmdata forKey:@"RecentScriptBookmarks" emptyFirst:YES];
    
    return YES;
}


//MARK: methods for singleton
static AppController *sharedInstance = nil;

+ (AppController *)sharedAppController
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        (void)[[AppController alloc] init];
    });
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
	
	__block id ret = nil;
	
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		sharedInstance = [super allocWithZone:zone];
		ret = sharedInstance;
	});
	
	return  ret;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


#pragma mark initilize
- (void)setTargetScriptTextForMode:(TargetMode) mode
{
    NSString *target_script_text = nil;
    switch (mode) {
        case ScriptEditorSelection:
            target_script_text = NSLocalizedString(@"ScriptEditorSelection",
                                                   @"Indicator of ScriptEditor's Selection mode");
            break;
        case ClipboardContents:
            target_script_text = NSLocalizedString(@"ClipboardContents",
                                                      @"Indicator of Clipboard Contents mode");
            break;
        case DropScriptFile:
            target_script_text = NSLocalizedString(@"DropScriptFile",
                                                   @"Indicator of File Drop mode");
            break;
        default:
            return;
    }
    
    [[NSUserDefaultsController sharedUserDefaultsController]
        setValue:target_script_text forKeyPath:@"values.TargetScript"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"TargetScriptBookmark"];
}

- (void)awakeFromNib
{
#if useLog
	NSLog(@"awakeFromNib");
#endif
	// setup FactorySettings
	NSString *defaults_plist = [[NSBundle mainBundle] 
								pathForResource:@"FactorySettings" ofType:@"plist"];
	NSDictionary *factory_defaults = [NSDictionary dictionaryWithContentsOfFile:defaults_plist];
	
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults registerDefaults:factory_defaults];
	
    // setup updater
#if SANDBOX
    /* remove script editor's selection button */
    NSRect ses_frame = scriptEditorSelectionButton.frame;
    [scriptEditorSelectionButton removeFromSuperview];
    NSRect frame = selectButton.frame;
    frame.origin.x += ses_frame.size.width;
    selectButton.frame = frame;
    frame = recentScriptsButton.frame;
    frame.origin.x += ses_frame.size.width;
    recentScriptsButton.frame = frame;
    
    /* remove donation menu and check for updates menu */
    [[checkForUpdatesMenuItem menu] removeItem:checkForUpdatesMenuItem];
    [[donationMenuItem menu] removeItem:donationMenuItem];
#else
    self.updater = [[SUUpdater alloc] init];
    checkForUpdatesMenuItem.action = @selector(checkForUpdates:);
    checkForUpdatesMenuItem.target = _updater;
#endif
    
	// set recentScriptsButton
	NSPopUpButtonCell *a_cell = [recentScriptsButton cell];
	[a_cell setBezelStyle:NSSmallSquareBezelStyle];
	[a_cell setArrowPosition:NSPopUpArrowAtCenter];
	[a_cell setUsesItemFromMenu:NO];
	
	[targetScriptBox setAcceptFileInfo:@[@{@"FileType": NSFileTypeDirectory,
													@"PathExtension": @"scptd"}, 
		@{@"FileType": NSFileTypeRegular,
													@"PathExtension": @"scpt"}, 
		@{@"FileType": NSFileTypeRegular,
												@"PathExtension": @"applescript"}, 
		@{@"PathExtension": @"app",
													 @"CreatorCode": @"aplt"}, 
		@{@"PathExtension": @"app",
										 @"CreatorCode": @"dplt"}]];
		
    if ([user_defaults boolForKey:@"ObtainScriptLinkTitleFromFilename"]) {
		NSComboBoxCell *a_cell = [scriptLinkTitleComboBox cell];
		[a_cell setObjectValue:@""];
		if (0 == [user_defaults integerForKey:@"TargetMode"]) {
            NSString *target = [user_defaults stringForKey:@"TargetScript"];
			[a_cell setPlaceholderString:[[target lastPathComponent] stringByDeletingPathExtension]];
		}
	}
    
	[mainWindow center];
	[mainWindow setFrameAutosaveName:@"Main"];
    
   
    if (NSAppKitVersionNumber > 1500) {
        [NSWindow setAllowsAutomaticWindowTabbing: NO];
    }
}

#pragma mark delegate methods for somethings
- (BOOL)dropBox:(NSView *)dbv acceptDrop:(id <NSDraggingInfo>)info item:(id)item
{
	NSURL *an_url = [item infoResolvingAliasFile][@"ResolvedURL"];
	return [self updateTargetScriptURL:an_url];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode 
												contextInfo:(void  *)contextInfo
{
	if (returnCode == NSOKButton) {
        NSURL *an_url = [panel URL];
		NSDictionary *alias_info = [an_url infoResolvingAliasFile];
		if (alias_info) {
			[self updateTargetScriptURL:alias_info[@"ResolvedURL"]];
			[[NSUserDefaults standardUserDefaults] setInteger:FileSelected forKey:@"TargetMode"];
		} else {
			[panel orderOut:self];
			NSAlert *an_alert = [NSAlert alertWithMessageText:@"Can't resolving alias"
							defaultButton:@"OK" alternateButton:nil otherButton:nil
							informativeTextWithFormat:@"No original item of '%@'",[an_url path] ];
			[an_alert beginSheetModalForWindow:mainWindow modalDelegate:self
														didEndSelector:nil contextInfo:nil];
		}
	}
}

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	[sheet orderOut:self];
}

#pragma mark delegate methods for NSApplication
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
#if useLog
	NSLog(@"application:openFile:%@", filename);
#endif
	return [self updateTargetScriptURL:[filename fileURL]];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillFinishLaunching");
#endif
}

- (IBAction)makeDonation:(id)sender
{
#if !SANDBOX
    [DonationReminder goToDonation];
#endif
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	TargetMode target_mode = (TargetMode)[user_defaults integerForKey:@"TargetMode"];
    
    NSError *error = nil;
    NSData *bmdata = nil;
    NSURL *an_url = nil;
    BOOL is_stale = NO;
	switch (target_mode) {
		case FileSelected:
            bmdata = [user_defaults dataForKey:@"TargetScriptBookmark"];
            if (bmdata) {
                an_url = [NSURL URLByResolvingBookmarkData:bmdata
                                    options:NSURLBookmarkResolutionWithoutUI|NSURLBookmarkResolutionWithSecurityScope
                                                         relativeToURL:nil
                                                   bookmarkDataIsStale:&is_stale
                                                                 error:&error];
                if ((is_stale || error)
                        || (![an_url checkResourceIsReachableAndReturnError:&error])) {
                    [user_defaults removeObjectForKey:@"TargetScriptBookmark"];
                    [user_defaults removeObjectForKey:@"TargetScript"];
                } else {
                    [[NSUserDefaultsController sharedUserDefaultsController]
                     setValue:an_url.path forKeyPath:@"values.TargetScript"];
                    break;
                }
            }
            target_mode = DropScriptFile;
            [[NSUserDefaults standardUserDefaults] setInteger:target_mode forKey:@"TargetMode"];
#if SANDBOX
        case ScriptEditorSelection:
            target_mode = DropScriptFile;
            [[NSUserDefaults standardUserDefaults] setInteger:target_mode forKey:@"TargetMode"];
#endif
        default:
            [self setTargetScriptTextForMode:target_mode];
	}
    
bail:
	[mainWindow orderFront:self];

#if !SANDBOX
    [DonationReminder remindDonation];
#endif
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[mainWindow saveFrameUsingName:@"Main"];
}

//MARK: actions

- (IBAction)showMonitorWindow:(id)sender
{
	MonitorWindowController *wc = [MonitorWindowController sharedWindowController];
	[wc showWindow:self];	
}

- (IBAction)showSettingWindow:(id)sender
{
	PreferencesWindowController *wc = [PreferencesWindowController sharedPreferencesWindowController];
	[wc showWindow:self];
}

- (IBAction)useClipboardContents:(id)sender
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setObject:@2 forKey:@"TargetMode"];
    [self setTargetScriptTextForMode:ClipboardContents];
}

- (IBAction)useScriptEditorSelection:(id)sender
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setObject:@1 forKey:@"TargetMode"];
    [self setTargetScriptTextForMode:ScriptEditorSelection];
}

- (void)selectTargetWithCompletionHandler:(void (^)(BOOL result))handler
{
    NSOpenPanel *a_panel = [NSOpenPanel openPanel];
    [a_panel setResolvesAliases:NO];
    [a_panel setAllowedFileTypes:@[@"scpt", @"scptd", @"applescript", @"app"]];
    [a_panel beginSheetModalForWindow:mainWindow
                    completionHandler:^(NSInteger result)
     {
         if (result != NSOKButton) return;
         NSURL *an_url = [a_panel URL];
         NSDictionary *alias_info = [an_url infoResolvingAliasFile];
         if (alias_info) {
             [self updateTargetScriptURL:alias_info[@"ResolvedURL"]];
             [[NSUserDefaults standardUserDefaults] setInteger:FileSelected forKey:@"TargetMode"];
             if (handler) handler(YES);
         } else {
             [a_panel orderOut:self];
             NSAlert *an_alert = [NSAlert alertWithMessageText:@"Can't resolving alias"
                                                 defaultButton:@"OK" alternateButton:nil otherButton:nil
                                     informativeTextWithFormat:@"No original item of '%@'",[an_url path] ];
             [an_alert beginSheetModalForWindow:mainWindow modalDelegate:self
                                 didEndSelector:nil contextInfo:nil];
             if (handler) handler(NO);
         }
     }];
}

- (IBAction)selectTarget:(id)sender
{
    [self selectTargetWithCompletionHandler:nil];
}

- (IBAction)popUpRecents:(id)sender
{
    NSInteger selidx = [sender indexOfSelectedItem];
    if (selidx < 1) return;
    
	UInt32 is_optkey = GetCurrentEventKeyModifiers() & optionKey;
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
    NSData *bmdata = [user_defaults objectInHistoryAtIndex:selidx forKey:@"RecentScriptBookmarks"];
    BOOL is_slate = NO;
    NSError *error = nil;
    NSURL *url = [NSURL URLByResolvingBookmarkData:bmdata
                                           options:NSURLBookmarkResolutionWithSecurityScope
                                     relativeToURL:nil bookmarkDataIsStale:&is_slate
                                             error:&error];
	if ((!is_optkey) && (!(is_slate || error))) {
		[[NSUserDefaultsController sharedUserDefaultsController] 
						setValue:url.path forKeyPath:@"values.TargetScript"];
		[user_defaults setObject:@0 forKey:@"TargetMode"];
        [user_defaults setObject:bmdata forKey:@"TargetScriptBookmark"];
	} else {
		[user_defaults removeFromHistoryAtIndex:selidx forKey:@"RecentScripts"];
	}
}

- (IBAction)useFileName:(id)sender
{
	if ([sender state] == NSOnState) {
		NSString *title_text;
        NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
		NSInteger target_mode = [user_defaults integerForKey:@"TargetMode"];
		if (target_mode != 0) {
			title_text = @"";			
		} else {
            NSString *target = [user_defaults stringForKey:@"TargetScript"];
			title_text = [[target lastPathComponent] stringByDeletingPathExtension];
		}
		[[scriptLinkTitleComboBox cell] setObjectValue:@""];
		[[scriptLinkTitleComboBox cell] setPlaceholderString:title_text];
	}
}

//MARK: Menu Titles

- (NSString *)bundleName
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
}

- (NSString *)buildMenuTitle:(NSString *)localizedStringName
{
    return [NSString stringWithFormat:NSLocalizedString(localizedStringName, @""), [self bundleName]];
}

- (NSString *)aboutMenuTitle
{
    return [self buildMenuTitle:@"AboutMenuTitle"];
}

- (NSString *)hideMenuTitle
{
    return [self buildMenuTitle:@"HideMenuTitle"];
}

- (NSString *)quitMenuTitle
{
    return [self buildMenuTitle:@"QuitMenuTitle"];
}

- (NSString *)helpMenuTitle
{
    return [self buildMenuTitle:@"HelpMenuTitle"];
}

@end
