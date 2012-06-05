#import "ASHTMLController.h"
#import "MonitorWindowController.h"

#define useLog 0

@interface ASKScriptCache : NSObject
{
}
+ (ASKScriptCache *)sharedScriptCache;
- (OSAScript *)scriptWithName:(NSString *)name;
@end


@implementation ASHTMLController

static ASHTMLController *sharedInstance = nil;

@synthesize script;

+ (ASHTMLController *)sharedASHTMLController
{
	@synchronized(self) {
		if (sharedInstance == nil) {
			[[self alloc] init]; // ここでは代入していない
		}
	}
	
	return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self) {
		if (sharedInstance == nil) {
			sharedInstance = [super allocWithZone:zone];
			return sharedInstance;  // 最初の割り当てで代入し、返す
		}
	}
	return nil; // 以降の割り当てではnilを返すようにする
}
	
- (id)copyWithZone:(NSZone *)zone
{
	return self;
}
	
- (id)retain
{
	return self;
}
	
- (NSUInteger)retainCount
{
	return UINT_MAX;  // 解放できないオブジェクトであることを示す
}
	
- (void)release
{
	// 何もしない
}
	
- (id)autorelease
{
	return self;
}
	
- (id)init
{
	self = [super init];
	if (sharedInstance) {
		/*self.script = [[ASKScriptCache sharedScriptCache] 
									scriptWithName:@"AppleScriptHTML"];
		 */
		
		/*
		NSString *path = [[NSBundle mainBundle] pathForResource:@"AppleScriptHTML"
												ofType:@"scpt" inDirectory:@"Scripts"];
		
		
		NSDictionary *err_info = nil;
		script = [[OSAScript alloc] initWithContentsOfURL:
									[NSURL fileURLWithPath:path]
												error:&err_info];
		
		[script executeHandlerWithName:@"setup_modules"
							 arguments:nil error:&err_info];
		if (err_info) {
			NSLog(@"Error : %@", [err_info description]);
			NSLog(@"%@", err_info);
			[NSApp activateIgnoringOtherApps:YES];
			NSRunAlertPanel(nil, [err_info objectForKey:OSAScriptErrorMessage], 
							@"OK", nil, nil);
		}
		 */
	}
	return self;
}

- (void)dealloc
{
	self.script = nil;
	[super dealloc];
}


void showError(NSDictionary *err_info)
{
	NSLog(@"Error : %@", [err_info description]);
	NSLog(@"%@", err_info);
	[NSApp activateIgnoringOtherApps:YES];
	NSRunAlertPanel(nil, [err_info objectForKey:OSAScriptErrorMessage], 
					@"OK", nil, nil);	
}

- (OSAScript *)script
{
	if (script) {
		return script;
	}
	
	NSDictionary *err_info = nil;	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"AppleScriptHTML"
										 ofType:@"scpt" inDirectory:@"Scripts"];
		
	OSAScript *scpt = [[OSAScript alloc] initWithContentsOfURL:
						[NSURL fileURLWithPath:path] error:&err_info];
		
	if (err_info) {
		showError(err_info);
		if (scpt) [scpt release];
		return nil;
	}
		
	[scpt executeHandlerWithName:@"setup_modules"
						 arguments:nil error:&err_info];
	if (err_info) {
		showError(err_info);
		if (scpt) [scpt release];
	}
	script = scpt;
	return script;
}

- (NSAppleEventDescriptor *)runHandlerWithName:(NSString *)handler
									arguments:(NSArray *)args
									sender:(id)sender
{
	OSAScript *scpt = [self script];
	if (!scpt) return nil;
	
	NSDictionary *error_info = nil;
	NSAppleEventDescriptor *result = 
			[scpt executeHandlerWithName:handler
							  arguments:args error:&error_info];
	if (error_info) {
		NSNumber *err_no = [error_info objectForKey:OSAScriptErrorNumber];
		NSString *msg = [error_info objectForKey:OSAScriptErrorMessage];
		NSAlert *alert = nil;
#if useLog
		NSLog(@"%@", [error_info description]);
#endif					
		switch ([err_no intValue]) {
			case 1500 : //No Target."
			case 1501 : //"No action is selected." 
			case 1502 :
			case 1503 : //"Failed to obtain AppleScript code"
			case 1504 :
#if useLog
				NSLog(@"%@", error_info);
#endif				
				msg = NSLocalizedString(msg, @"");
				alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error :", @"")
										defaultButton:@"OK" 
									alternateButton:nil 
										otherButton:nil
							informativeTextWithFormat:msg];
				
				
				break;
			case -128 :
				break;
			default:
				alert = [NSAlert alertWithMessageText:@"AppleScript Error"
								 defaultButton:@"OK" alternateButton:nil otherButton:nil
								informativeTextWithFormat:@"%@\nNumber: %@", 
						 [error_info objectForKey:OSAScriptErrorMessage],
						 err_no];
				break;
		}
		if (alert) {
			[alert beginSheetModalForWindow:[sender window]
							  modalDelegate:nil
							 didEndSelector:nil
								contextInfo:nil];
		}
		return nil;
	}
	return result;
}

- (void)generateCSS:(id)sender
{
	NSAppleEventDescriptor *css = [self runHandlerWithName:@"generate_css" 
												 arguments:nil
													sender:sender];
	if (!css) return;
		
	MonitorWindowController *wc = [MonitorWindowController sharedWindowController];
	[wc showWindow:self];
	[wc setContent:[css stringValue] type:@"css"];
}

- (void)startIndicator
{
	[indicator setHidden:NO];
	[indicator startAnimation:self];	
}

- (void)stopIndicator
{
	[indicator stopAnimation:self];
	[indicator setHidden:YES];
}

- (IBAction)copyToClipboard:(id)sender
{
	[self startIndicator];
	NSAppleEventDescriptor *result = [self runHandlerWithName:@"copy_to_clipboard" 
													arguments:nil
													   sender:sender];
	if ('reco' == [result descriptorType]) {
		NSString *result_text = [[result descriptorForKeyword:'conT'] stringValue];
		NSString *content_kind = [[result descriptorForKeyword:'kind'] stringValue]; 
		NSPasteboard *pboard = [NSPasteboard generalPasteboard];
		[pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
		[pboard setString:result_text forType:NSStringPboardType];
		[MonitorWindowController setContent:result_text type:content_kind];
	}
	[self stopIndicator];
}

struct LocationAndName {
	NSString *location;
	NSString *name;
	NSString *extension;
};
	 
- (struct LocationAndName)defaultLocationAndName:(id)sender
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	Boolean is_css = [user_defaults boolForKey:@"GenerateCSS"];
	Boolean is_convert = [user_defaults boolForKey:@"CodeToHTML"];
	Boolean is_scriptlink = [user_defaults boolForKey:@"MakeScriptLink"];
	Boolean is_save_to_souce_location = [user_defaults boolForKey:@"SaveToSourceLocation"];
	Boolean use_scripteditor = [user_defaults boolForKey:@"UseScriptEditorSelection"];
	NSString *default_name = nil;
	NSString *default_location = nil;
	NSString *extension = @"html";
	if (is_css && (!(is_convert || is_scriptlink))) {
		default_name = @"AppleScript.css";
		extension = @"css";
	} else if (use_scripteditor) {
		NSAppleEventDescriptor *result = [self runHandlerWithName:@"path_on_scripteditor"
														arguments:nil
														   sender:sender];
		if ('utxt' == [result descriptorType]) {
			NSString *path = [result stringValue];
			default_name = [[[path lastPathComponent] 
									stringByDeletingPathExtension]
									stringByAppendingPathExtension:@"html"];
			if (is_save_to_souce_location) {
				default_location = [path stringByDeletingLastPathComponent];
			}
		} else {
			default_name = @"AppleScript HTML.html";
		}
		
	} else {
		NSString *path = [user_defaults stringForKey:@"TargetScript"];
		default_name = [[[path lastPathComponent] 
						 stringByDeletingPathExtension]
						stringByAppendingPathExtension:@"html"];
		if (is_save_to_souce_location) {
			default_location = [path stringByDeletingLastPathComponent];
		}		
	}
	struct LocationAndName result = {default_location, default_name, extension};
	return result;
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode 
										contextInfo:(void *)contextInfo
{
	NSString *file = [(NSString *)contextInfo autorelease];
	switch (returnCode) {
		case NSAlertDefaultReturn:
			[[NSWorkspace sharedWorkspace] openFile:file];
			break;
		case  NSAlertOtherReturn:
			[[NSWorkspace sharedWorkspace] selectFile:file inFileViewerRootedAtPath:@""];
			break;
		default:
			break;
	}
}

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode 
			contextInfo:(void *)contextInfo
{
	if (returnCode != NSOKButton) return;
	NSError *error = nil;
	NSString *file = [sheet filename];
	NSAppleEventDescriptor *html_rec = [(NSAppleEventDescriptor *)contextInfo autorelease];
	NSString *string = [[html_rec descriptorForKeyword:'conT'] stringValue];
	[string writeToFile:file
			 atomically:NO encoding:NSUTF8StringEncoding
				  error:&error];
	if (error) {
		[sheet orderOut:self];
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert beginSheetModalForWindow:mainWindow
						  modalDelegate:self
						 didEndSelector:nil
							contextInfo:nil];
		return;
	}
	NSString *content_kind = [[html_rec descriptorForKeyword:'kind'] stringValue]; 
	[MonitorWindowController setContent:string type:content_kind];	
	[self stopIndicator];
	[sheet orderOut:self];
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Success to Make a HTML file.",@"")
									 defaultButton:NSLocalizedString(@"Open", @"")
								   alternateButton:NSLocalizedString(@"Cancel",@"")
									   otherButton:NSLocalizedString(@"Reveal", @"")
						 informativeTextWithFormat:@""];
	[alert beginSheetModalForWindow:mainWindow
					  modalDelegate:self
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
						contextInfo:[file retain]];
}

- (IBAction)saveToFile:(id)sender
{
	[self startIndicator];
	NSAppleEventDescriptor *result = [self runHandlerWithName:@"save_to_file" 
													arguments:nil
													   sender:sender];
	struct LocationAndName default_loc_name = [self defaultLocationAndName:sender];
	NSSavePanel *save_panel = [NSSavePanel savePanel];
	[save_panel setAllowedFileTypes:[NSArray arrayWithObject:default_loc_name.extension]];
	[save_panel setCanSelectHiddenExtension:YES];
	[save_panel beginSheetForDirectory:default_loc_name.location
								  file:default_loc_name.name
						modalForWindow:mainWindow
						 modalDelegate:self
						didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
						   contextInfo:[result retain]];
	
	//[self stopIndicator];
}

@end
