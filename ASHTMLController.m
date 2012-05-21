#import "ASHTMLController.h"
#import "MonitorWindowController.h"

@interface ASKScriptCache : NSObject
{
}
+ (ASKScriptCache *)sharedScriptCache;
- (OSAScript *)scriptWithName:(NSString *)name;
@end


@implementation ASHTMLController

static ASHTMLController *sharedInstance = nil;

@synthesize script;

+ (id)sharedASHTMLController
{
	if (!sharedInstance) {
		sharedInstance = [[self alloc] init];
	}
	return sharedInstance;
}

- (id)init
{
	self = [super init];
	if (self) {
		self.script = [[ASKScriptCache sharedScriptCache] scriptWithName:@"AppleScriptHTML"];
	}
	return self;
}

- (void)dealloc
{
	self.script = nil;
	[super dealloc];
}

- (NSAppleEventDescriptor *)runHandlerWithName:(NSString *)handler
									arguments:(NSArray *)args
{
	NSDictionary *error_info = nil;
	NSAppleEventDescriptor *result = 
	[script executeHandlerWithName:handler
							  arguments:args error:&error_info];
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
		return nil;
	}
	return result;
}

- (void)generateCSS:(id)sender
{
	NSAppleEventDescriptor *css = [self runHandlerWithName:@"generate_css" arguments:nil];
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
													arguments:nil];
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
	 
- (struct LocationAndName)defaultLocationAndName
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
														arguments:nil];
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

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode 
			contextInfo:(void *)contextInfo
{
	if (returnCode == NSCancelButton) return;
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
	
	
}

- (IBAction)saveToFile:(id)sender
{
	[self startIndicator];
	NSAppleEventDescriptor *result = [self runHandlerWithName:@"save_to_file" arguments:nil];
	struct LocationAndName default_loc_name = [self defaultLocationAndName];
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
