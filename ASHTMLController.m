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
	[self runHandlerWithName:@"copy_to_clipboard" arguments:nil];
	[self stopIndicator];
}

- (IBAction)saveToFile:(id)sender
{
	[self startIndicator];
	[self runHandlerWithName:@"save_to_file" arguments:nil];
	[self stopIndicator];
}

@end
