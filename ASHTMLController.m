#import "ASHTMLController.h"
#import "MonitorWindowController.h"

#define useLog 0

@interface ASHTMLProcessor : NSObject
- (NSString *)generateCSS;
- (NSDictionary *)generateContents;
- (NSString *)pathOnScriptEditor;
- (NSDictionary *)saveToFile;
- (NSDictionary *)errorInfo;
@end

@implementation ASHTMLController

static ASHTMLController *sharedInstance = nil;

+ (ASHTMLController *)sharedASHTMLController
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        (void)[[self alloc] init];
    });
	
	return sharedInstance;
}


+ (id)allocWithZone:(NSZone *)zone {
	
	__block id ret = nil;
	
	static dispatch_once_t once;
	dispatch_once( &once, ^{
		sharedInstance = [super allocWithZone:zone];
		ret = sharedInstance;
	});
	
	return  ret;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

void showError(NSDictionary *err_info)
{
	NSLog(@"Error : %@", [err_info description]);
	NSLog(@"%@", err_info);
	[NSApp activateIgnoringOtherApps:YES];
	NSRunAlertPanel(nil, err_info[OSAScriptErrorMessage], 
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
		NSNumber *err_no = error_info[OSAScriptErrorNumber];
		NSString *msg = error_info[OSAScriptErrorMessage];
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
						 error_info[OSAScriptErrorMessage],
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
	NSString *css = [ashtmlProcessor generateCSS];
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
	//[self startIndicator];
	NSDictionary *result = [ashtmlProcessor generateContents];
	if (!result) {
		NSDictionary *error_info = [ashtmlProcessor errorInfo];
		NSString *message = NSLocalizedString(error_info[@"message"], @"");
		NSError *error = [NSError errorWithDomain:@"AppleScriptHTMLErrorDomain"
											 code:[error_info[@"number"] intValue]
										 userInfo:@{NSLocalizedDescriptionKey: message}];
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert beginSheetModalForWindow:mainWindow
						  modalDelegate:self
						 didEndSelector:nil
							contextInfo:nil];
		[self stopIndicator];
		return;
	}
	NSString *result_text = result[@"content"];
	NSString *content_kind = result[@"kind"];
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	[pboard declareTypes:@[NSStringPboardType] owner:nil];
	[pboard setString:result_text forType:NSStringPboardType];
	[MonitorWindowController setContent:result_text type:content_kind];
	[self stopIndicator];
}
	 
- (NSDictionary *)defaultLocationAndName:(id)sender
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
		NSString *path = [ashtmlProcessor pathOnScriptEditor];
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
	return @{@"location": default_location, @"name": default_name, @"extension":extension};
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode 
										contextInfo:(void *)contextInfo
{
	NSString *file = [(__bridge_transfer NSURL *)contextInfo path];
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

- (void)saveASHTML:(NSDictionary *)ASTHMLDict toURL:(NSURL *)anURL error:(NSError **)err
{
	NSString *string = ASTHMLDict[@"content"];
	[string writeToURL:anURL
            atomically:NO encoding:NSUTF8StringEncoding
                 error:err];
	if (err) {
        return;
	}
	NSString *content_kind = ASTHMLDict[@"kind"];
	[MonitorWindowController setContent:string type:content_kind];	
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Success to Make a HTML file.",@"")
									 defaultButton:NSLocalizedString(@"Open", @"")
								   alternateButton:NSLocalizedString(@"Cancel",@"")
									   otherButton:NSLocalizedString(@"Reveal", @"")
						 informativeTextWithFormat:@""];
	
    [alert beginSheetModalForWindow:mainWindow
					  modalDelegate:self
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
						contextInfo:(__bridge_retained void *)anURL];
}

- (IBAction)saveToFile:(id)sender
{
	[self startIndicator];
	NSDictionary *result_ASHTML = [ashtmlProcessor saveToFile];
	if (!result_ASHTML) {
		NSDictionary *error_info = [ashtmlProcessor errorInfo];
		NSString *message = NSLocalizedString(error_info[@"message"], @"");
		NSError *error = [NSError errorWithDomain:@"AppleScriptHTMLErrorDomain"
											 code:[error_info[@"number"] intValue]
                                         userInfo:@{NSLocalizedDescriptionKey: message}];
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert beginSheetModalForWindow:mainWindow
						  modalDelegate:self
						 didEndSelector:nil
							contextInfo:nil];
		[self stopIndicator];
		return;
	}
	NSDictionary *default_loc_name = [self defaultLocationAndName:sender];
	NSSavePanel *save_panel = [NSSavePanel savePanel];
	[save_panel setAllowedFileTypes:@[default_loc_name[@"extension"]]];
	[save_panel setCanSelectHiddenExtension:YES];
    [save_panel setDirectoryURL:[NSURL fileURLWithPath:default_loc_name[@"location"]]];
    [save_panel setNameFieldStringValue:default_loc_name[@"name"]];
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
