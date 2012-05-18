#import "MonitorWindowController.h"

@implementation MonitorWindowController

@synthesize contentType;

static MonitorWindowController *sharedInstance = nil;
static NSString *windowName = @"MonitorWindow";


+ (id)sharedWindowController
{
	if (!sharedInstance) {
		sharedInstance = [[self alloc] initWithWindowNibName:windowName];
	}
	return sharedInstance;
}

+ (void)setContent:(NSString *)string type:(NSString *)type
{
	if (!sharedInstance) {
		return;
	}
	[sharedInstance setContent:string type:type];
}

- (void)setContent:(NSString *)string type:(NSString *)type
{
	//[self showWindow:self];
	[self setContentType:type];
	[monitorTextView setString:string];
}

- (void)awakeFromNib
{
	NSWindow *a_window = [self window];
	[a_window center];
	[a_window setFrameUsingName:windowName];	
}

-(void)windowWillClose:(NSNotification *)notification
{
	[[self window] saveFrameUsingName:windowName];
}

@end
