#import <Carbon/Carbon.h>
#import "AppController.h"
#import <DonationReminder/DonationReminder.h>
#import "PathExtra.h"
#import "NSUserDefaultsExtensions.h"
#import "DropBox.h"

#define useLog 0

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
		[recentScriptsButton setTitle:@""];
		return YES;
	}
	return NO;
}

#pragma mark initilize
+ (void)initialize
{
	NSString *defaults_plist = [[NSBundle mainBundle] 
						pathForResource:@"FactorySettings" ofType:@"plist"];
	NSDictionary *factory_defaults = [NSDictionary dictionaryWithContentsOfFile:defaults_plist];
	
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults registerDefaults:factory_defaults];
}

- (void)awakeFromNib
{
#if useLog
	NSLog(@"awakeFromNib");
#endif
	[recentScriptsButton setTitle:@""];
	NSPopUpButtonCell *a_cell = [recentScriptsButton cell];
	[a_cell setBezelStyle:NSSmallSquareBezelStyle];
	[a_cell setArrowPosition:NSPopUpArrowAtCenter];
	
	[targetScriptBox setAcceptFileInfo:[NSArray arrayWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:NSFileTypeDirectory, @"FileType",
													@"scptd", @"PathExtension", nil], 
		[NSDictionary dictionaryWithObjectsAndKeys:NSFileTypeRegular, @"FileType",
													@"scpt", @"PathExtension", nil], nil]];
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults] ;
	if ([user_defaults boolForKey:@"ObtainScriptLinkTitleFromFilename"]) {
		NSString *target = [user_defaults stringForKey:@"TargetScript"];
		NSString *use_se_selection = NSLocalizedString(@"ScriptEditorSelection", 
											@"Indicator of ScriptEditor's Selection mode");
		NSComboBoxCell *a_cell = [scriptLinkTitleComboBox cell];
		[a_cell setObjectValue:@""];
		if (![target isEqualToString:use_se_selection]) {
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
	[self setTargetScript:item];
	return YES;
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
	[settingWindow orderFront:self];
	[settingWindow makeMainWindow];
	[settingWindow makeKeyWindow];
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
			types:[NSArray arrayWithObjects:@"scpt", @"scptd", nil]
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
	[recentScriptsButton setTitle:@""];
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

@end
