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
	
- (oneway void)release
{
	// 何もしない
}
	
- (id)autorelease
{
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



- (NSAppleEventDescriptor *)runHandlerWithName:(NSString *)handler
									arguments:(NSArray *)args
									sender:(id)sender
{
	if (!_script) return nil;
	
	NSDictionary *error_info = nil;
	NSAppleEventDescriptor *result = 
			[_script executeHandlerWithName:handler
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
							informativeTextWithFormat:@"%@", msg];
				
				
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
	NSString *css = [ASHTMLProcessor generateCSS];
	 if (!css) return;
		
	MonitorWindowController *wc = [MonitorWindowController sharedWindowController];
	[wc showWindow:self];
	[wc setContent:css type:@"css"];
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
	NSDictionary *result = [ASHTMLProcessor copyToClipboard];
	if (!result) {
		NSDictionary *error_info = [ASHTMLProcessor errorInfo];
		NSString *message = NSLocalizedString([error_info objectForKey:@"message"], @"");
		NSError *error = [NSError errorWithDomain:@"AppleScriptHTMLErrorDomain"
											 code:[[error_info objectForKey:@"number"] intValue]
										 userInfo:(void *)[NSDictionary dictionaryWithObject:message
																					  forKey:NSLocalizedDescriptionKey]];
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert beginSheetModalForWindow:mainWindow
						  modalDelegate:self
						 didEndSelector:nil
							contextInfo:nil];
		[self stopIndicator];
		return;
	}
	NSString *result_text = [result objectForKey:@"content"];
	NSString *content_kind = [result objectForKey:@"kind"];
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	[pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[pboard setString:result_text forType:NSStringPboardType];
	[MonitorWindowController setContent:result_text type:content_kind];
bail:	
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
	int css_mode_index = [user_defaults integerForKey:@"CSSModeIndex"];
	Boolean is_convert = [user_defaults boolForKey:@"CodeToHTML"];
	Boolean is_scriptlink = [user_defaults boolForKey:@"MakeScriptLink"];
	Boolean is_save_to_souce_location = [user_defaults boolForKey:@"SaveToSourceLocation"];
	int target_mode = [user_defaults integerForKey:@"TargetMode"];
	NSString *default_name = nil;
	NSString *default_location = nil;
	NSString *extension = @"html";
	if ((css_mode_index == 0) && (!(is_convert || is_scriptlink))) {
		default_name = @"AppleScript.css";
		extension = @"css";
	} else if (target_mode == 1) { // target is script editor's selection
		NSString *path = [ASHTMLProcessor pathOnScriptEditor];
		if (path) {
			default_name = [[[path lastPathComponent] 
									stringByDeletingPathExtension]
									stringByAppendingPathExtension:@"html"];
			if (is_save_to_souce_location) {
				default_location = [path stringByDeletingLastPathComponent];
			}
		} else {
			default_name = @"AppleScript HTML.html";
		}
		
	} else if (target_mode == 2) { // clipbpoard
		default_name = @"Clipboard.html";
		extension = @"html";	
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
	NSString *file = [(NSURL *)contextInfo path];
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
	CFRelease(file);
}

- (void)saveASHTML:(NSDictionary *)ASTHMLDict toURL:(NSURL *)anURL error:(NSError **)err
{
	NSString *string = [ASTHMLDict objectForKey:@"content"];
	[string writeToURL:anURL
            atomically:NO encoding:NSUTF8StringEncoding
                 error:err];
	if (err) {
        return;
	}
	NSString *content_kind = [ASTHMLDict objectForKey:@"kind"];
	[MonitorWindowController setContent:string type:content_kind];	
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Success to Make a HTML file.",@"")
									 defaultButton:NSLocalizedString(@"Open", @"")
								   alternateButton:NSLocalizedString(@"Cancel",@"")
									   otherButton:NSLocalizedString(@"Reveal", @"")
						 informativeTextWithFormat:@""];
	
    [alert beginSheetModalForWindow:mainWindow
					  modalDelegate:self
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
						contextInfo:(void *)CFRetain(anURL)];
}

- (IBAction)saveToFile:(id)sender
{
	[self startIndicator];
	NSDictionary *result_ASHTML = [ASHTMLProcessor saveToFile];
	if (!result_ASHTML) {
		NSDictionary *error_info = [ASHTMLProcessor errorInfo];
		NSString *message = NSLocalizedString([error_info objectForKey:@"message"], @"");
		NSError *error = [NSError errorWithDomain:@"AppleScriptHTMLErrorDomain"
											 code:[[error_info objectForKey:@"number"] intValue]
						  userInfo:(void *)[NSDictionary dictionaryWithObject:message
															   forKey:NSLocalizedDescriptionKey]];
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert beginSheetModalForWindow:mainWindow
						  modalDelegate:self
						 didEndSelector:nil
							contextInfo:nil];
		[self stopIndicator];
		return;
	}
	struct LocationAndName default_loc_name = [self defaultLocationAndName:sender];
	NSSavePanel *save_panel = [NSSavePanel savePanel];
	[save_panel setAllowedFileTypes:[NSArray arrayWithObject:default_loc_name.extension]];
	[save_panel setCanSelectHiddenExtension:YES];
    [save_panel setDirectoryURL:[NSURL fileURLWithPath:default_loc_name.location]];
    [save_panel setNameFieldStringValue:default_loc_name.name];
    [save_panel beginSheetModalForWindow:mainWindow
                       completionHandler:^(NSInteger result) {
                [self stopIndicator];
                if (result != NSOKButton) {
                    return;
                }
                NSError *error = nil;
                [save_panel orderOut:self];
                [self saveASHTML:result_ASHTML toURL:[save_panel URL] error:&error];
                if (error) {
                    NSAlert *alert = [NSAlert alertWithError:error];
                    [alert beginSheetModalForWindow:mainWindow
                                      modalDelegate:self
                                     didEndSelector:nil
                                        contextInfo:nil];
                }
            }];
}

@end
