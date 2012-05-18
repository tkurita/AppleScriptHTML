#import <Carbon/Carbon.h>
#import "AppController.h"
#import <DonationReminder/DonationReminder.h>
#import "PathExtra.h"
#import "NSUserDefaultsExtensions.h"
#import "DropBox.h"
#import "PreferencesWindowController.h"
#import <OSAKit/OSAScript.h>

#define useLog 0

@interface ASKScriptCache : NSObject
{
}
+ (ASKScriptCache *)sharedScriptCache;
- (OSAScript *)scriptWithName:(NSString *)name;
@end

@implementation AppController

#pragma mark services for scripts

#pragma mark private methods

- (BOOL)setTargetScript:(NSString *)a_path
{
	[[NSUserDefaultsController sharedUserDefaultsController]
					setValue:a_path forKeyPath:@"values.TargetScript"];
	NSString *use_se_selection = NSLocalizedString(@"ScriptEditorSelection", 
											@"Indicator of ScriptEditor's Selection mode");
	if (![a_path isEqualToString:use_se_selection]) {
		[[NSUserDefaults standardUserDefaults] addToHistory:a_path forKey:@"RecentScripts" emptyFirst:YES];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"UseScriptEditorSelection"];
		return YES;
	}
	return NO;
}

#pragma mark initilize

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
	
	[targetScriptBox setAcceptFileInfo:[NSArray arrayWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:NSFileTypeDirectory, @"FileType",
													@"scptd", @"PathExtension", nil], 
		[NSDictionary dictionaryWithObjectsAndKeys:NSFileTypeRegular, @"FileType",
													@"scpt", @"PathExtension", nil], 
		[NSDictionary dictionaryWithObjectsAndKeys:@"app", @"PathExtension",
													 @"aplt", @"CreatorCode", nil], 
		[NSDictionary dictionaryWithObjectsAndKeys:@"app", @"PathExtension",
										 @"dplt", @"CreatorCode", nil], 										
										nil]];
		
	if ([user_defaults boolForKey:@"ObtainScriptLinkTitleFromFilename"]) {
		NSComboBoxCell *a_cell = [scriptLinkTitleComboBox cell];
		[a_cell setObjectValue:@""];
		if (![user_defaults boolForKey:@"UseScriptEditorSelection"] ) {
			NSString *target = [user_defaults stringForKey:@"TargetScript"];
			[a_cell setPlaceholderString:[[target lastPathComponent] stringByDeletingPathExtension]];
		}
	}
	[mainWindow center];
	[mainWindow setFrameAutosaveName:@"Main"];
	[monitorWindow center];
	[monitorWindow setFrameAutosaveName:@"Monitor"];
	[settingWindow center];
	[settingWindow setFrameAutosaveName:@"Setting"];

}

#pragma mark delegate methods for somethings
- (BOOL)dropBox:(NSView *)dbv acceptDrop:(id <NSDraggingInfo>)info item:(id)item
{
	item = [[item infoResolvingAliasFile] objectForKey:@"ResolvedPath"];
	return [self setTargetScript:item];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode 
												contextInfo:(void  *)contextInfo
{
	if (returnCode == NSOKButton) {
		NSString *a_path = [panel filename];
		NSDictionary *alias_info = [a_path infoResolvingAliasFile];
		if (alias_info) {
			[self setTargetScript:[alias_info objectForKey:@"ResolvedPath"] ];
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"UseScriptEditorSelection"];
		} else {
			[panel orderOut:self];
			NSAlert *an_alert = [NSAlert alertWithMessageText:@"Can't resolving alias"
							defaultButton:@"OK" alternateButton:nil otherButton:nil
							informativeTextWithFormat:@"No original item of '%@'",a_path ];
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
	[DonationReminder remindDonation];
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	if ([user_defaults boolForKey:@"UseScriptEditorSelection"] ) {
		NSString *use_se_selection = NSLocalizedString(@"ScriptEditorSelection", @"Indicator of ScriptEditor's Selection mode");
		[user_defaults setObject:use_se_selection forKey:@"TargetScript"];
	} else {
		NSString *a_path = [user_defaults stringForKey:@"TargetScript"];
		if (a_path) {
			if (![a_path fileExists]) {
				[user_defaults removeObjectForKey:@"TargetScript"];
			}
		}
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
	[monitorWindow saveFrameUsingName:@"Monitor"];
	[settingWindow saveFrameUsingName:@"Setting"];
}

#pragma mark actions

- (IBAction)showMonitorWindow:(id)sender
{
	[monitorWindow orderFront:self];
	[monitorWindow makeMainWindow];
	[monitorWindow makeKeyWindow];
}

- (IBAction)showSettingWindow:(id)sender
{
	PreferencesWindowController *wc = [PreferencesWindowController sharedPreferencesWindowController];
	[wc showWindow:self];
}

- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
}

- (IBAction)useScriptEditorSelection:(id)sender
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setBool:YES forKey:@"UseScriptEditorSelection"];
	NSString *use_se_selection = NSLocalizedString(@"ScriptEditorSelection", 
								@"Indicator of ScriptEditor's Selection mode");
	[[NSUserDefaultsController sharedUserDefaultsController]
				setValue:use_se_selection forKeyPath:@"values.TargetScript"];
}

- (IBAction)selectTarget:(id)sender
{
	NSOpenPanel *a_panel = [NSOpenPanel openPanel];
	[a_panel setResolvesAliases:NO];
	[a_panel beginSheetForDirectory:nil file:nil 
			types:[NSArray arrayWithObjects:@"scpt", @"scptd", @"app", nil]
			modalForWindow:mainWindow modalDelegate:self
			didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
			contextInfo:nil];
}

- (IBAction)popUpRecents:(id)sender
{
	NSString *a_path = [[sender selectedItem] title];
	UInt32 is_optkey = GetCurrentEventKeyModifiers() & optionKey;
	if ((!is_optkey) && [a_path fileExists]) {
		[[NSUserDefaultsController sharedUserDefaultsController] 
						setValue:a_path forKeyPath:@"values.TargetScript"];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"UseScriptEditorSelection"];
	} else {
		[[NSUserDefaults standardUserDefaults] removeFromHistory:a_path
												forKey:@"RecentScripts"];
	}
}

- (IBAction)useFileName:(id)sender
{
	if ([sender state] == NSOnState) {
		NSString *title_text;
		NSString *target = [[NSUserDefaults standardUserDefaults] stringForKey:@"TargetScript"];
		NSString *use_se_selection = NSLocalizedString(@"ScriptEditorSelection", 
												@"Indicator of ScriptEditor's Selection mode");
		if ([target isEqualToString:use_se_selection]) {
			title_text = @"";			
		} else {
			title_text = [[target lastPathComponent] stringByDeletingPathExtension];
		}
		[[scriptLinkTitleComboBox cell] setObjectValue:@""];
		[[scriptLinkTitleComboBox cell] setPlaceholderString:title_text];
	}
}

- (void)monitorCSS:(id)sender
{
	OSAScript *script = [[ASKScriptCache sharedScriptCache] scriptWithName:@"AppleScriptHTML"];
	NSDictionary *error_info = nil;
	NSAppleEventDescriptor *result = 
		[script executeHandlerWithName:@"generate_css"
					arguments:nil error:&error_info];
	if (error_info) {
		NSNumber *err_no = [error_info objectForKey:OSAScriptErrorNumber];
		if ([err_no intValue] != -128) {
			[[NSAlert alertWithMessageText:@"AppleScript Error"
							 defaultButton:@"OK" alternateButton:nil otherButton:nil
				 informativeTextWithFormat:@"%@\nNumber: %@", 
			  [error_info objectForKey:OSAScriptErrorMessage],
			  err_no] runModal];
#if useLog
			NSLog(@"%@", [error_info description]);
#endif			
		}
		return;
	}
	[self showMonitorWindow:sender];
	[monitorTextView setString:[result stringValue]];
}

@end
