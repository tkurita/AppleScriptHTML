#import <Carbon/Carbon.h>
#import "AppController.h"
#import "PathExtra/PathExtra.h"
#import "NSUserDefaultsExtensions.h"
#import "DropBox/DropBox.h"
#import "PreferencesWindowController.h"
#import "MonitorWindowController.h"

#define useLog 0

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

#pragma mark private methods

- (BOOL)setTargetScript:(NSString *)a_path
{
	[[NSUserDefaultsController sharedUserDefaultsController]
					setValue:a_path forKeyPath:@"values.TargetScript"];
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setObject:@0 forKey:@"TargetMode"];
	[user_defaults addToHistory:a_path forKey:@"RecentScripts" emptyFirst:YES];
	return YES;
}

#pragma mark methods for singleton
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
void setTargetScriptTextForMode(NSInteger mode)
{
    NSString *target_script_text = nil;
    switch (mode) {
        case 1:
            target_script_text = NSLocalizedString(@"ScriptEditorSelection",
                                                   @"Indicator of ScriptEditor's Selection mode");
            break;
        case 2:
            target_script_text = NSLocalizedString(@"ClipboardContents",
                                                      @"Indicator of Clipboard Contents mode");
            break;
        default:
            return;
    }
    [[NSUserDefaultsController sharedUserDefaultsController]
        setValue:target_script_text forKeyPath:@"values.TargetScript"];
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
	item = [item infoResolvingAliasFile][@"ResolvedPath"];
	return [self setTargetScript:item];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode 
												contextInfo:(void  *)contextInfo
{
	if (returnCode == NSOKButton) {
        NSURL *an_url = [panel URL];
		NSDictionary *alias_info = [an_url infoResolvingAliasFile];
		if (alias_info) {
			[self setTargetScript:[alias_info[@"ResolvedURL"] path]];
			[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"TargetMode"];
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
	NSLog(filename);
#endif
	return [self setTargetScript:filename];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillFinishLaunching");
#endif
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSInteger target_mode = [user_defaults integerForKey:@"TargetMode"];
	NSString *a_path = [user_defaults stringForKey:@"TargetScript"];
	switch (target_mode) {
		case 0:
			if (a_path) {
				if (![a_path fileExists]) {
					[user_defaults removeObjectForKey:@"TargetScript"];
				}
			}
			break;
        default:
            setTargetScriptTextForMode(target_mode);
	}
	[mainWindow orderFront:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[mainWindow saveFrameUsingName:@"Main"];
}

#pragma mark actions

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
    setTargetScriptTextForMode(2);
}

- (IBAction)useScriptEditorSelection:(id)sender
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setObject:@1 forKey:@"TargetMode"];
    setTargetScriptTextForMode(1);
}

- (IBAction)selectTarget:(id)sender
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
             [self setTargetScript:[alias_info[@"ResolvedURL"] path]];
             [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"TargetMode"];
         } else {
             [a_panel orderOut:self];
             NSAlert *an_alert = [NSAlert alertWithMessageText:@"Can't resolving alias"
                                                 defaultButton:@"OK" alternateButton:nil otherButton:nil
                                     informativeTextWithFormat:@"No original item of '%@'",[an_url path] ];
             [an_alert beginSheetModalForWindow:mainWindow modalDelegate:self
                                 didEndSelector:nil contextInfo:nil];
         }
     }];
}

- (IBAction)popUpRecents:(id)sender
{
	NSString *a_path = [[sender selectedItem] title];
	UInt32 is_optkey = GetCurrentEventKeyModifiers() & optionKey;
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	if ((!is_optkey) && [a_path fileExists]) {
		[[NSUserDefaultsController sharedUserDefaultsController] 
						setValue:a_path forKeyPath:@"values.TargetScript"];
		[user_defaults setObject:@0 forKey:@"TargetMode"];
	} else {
		[user_defaults removeFromHistory:a_path forKey:@"RecentScripts"];
	}
}

- (IBAction)useFileName:(id)sender
{
	if ([sender state] == NSOnState) {
		NSString *title_text;
		NSInteger target_mode = [[NSUserDefaults standardUserDefaults] integerForKey:@"TargetMode"];
		if (target_mode != 0) {
			title_text = @"";			
		} else {
			NSString *target = [[NSUserDefaults standardUserDefaults] 
												stringForKey:@"TargetScript"];
			title_text = [[target lastPathComponent] stringByDeletingPathExtension];
		}
		[[scriptLinkTitleComboBox cell] setObjectValue:@""];
		[[scriptLinkTitleComboBox cell] setPlaceholderString:title_text];
	}
}

@end
