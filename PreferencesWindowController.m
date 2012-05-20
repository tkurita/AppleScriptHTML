#import "PreferencesWindowController.h"
#import "ASFormatting.h"
#import "NSAppleEventDescriptor+NDScriptData.h"
#import "AppController.h"
#import "MonitorWindowController.h"
#import "ASHTMLController.h"

static PreferencesWindowController *sharedInstance = nil;
static NSString *frameName = @"PreferencesWindow";

@implementation PreferencesWindowController

+ (id)sharedPreferencesWindowController
{
	if (!sharedInstance) {
		sharedInstance = [[PreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindow"];
	}
	return sharedInstance;
}

- (NSArray *)styleNamesAndCSSClassNames
{
	NSAppleEventDescriptor *style_names_descriptor = [ASFormatting styleNames];
	NSArray *style_names = [style_names_descriptor objectValue];
	NSArray *class_names = [[NSUserDefaults standardUserDefaults] objectForKey:@"CSSClassNames"];
	if (!class_names) {
		class_names = [NSMutableArray array];
	}	
	NSArray *attributes = [ASFormatting sourceAttributes];
	NSMutableArray *a_result = [NSMutableArray array];
	int n = 0;
	for (NSString *a_name in style_names) {
		NSString *cname = @"";
		if ([class_names count] > n) {
			cname = [class_names objectAtIndex:n];
			if (!cname) cname = @"";
		}
		NSAttributedString *styled_name = [[NSAttributedString alloc] initWithString:a_name
																  attributes:[attributes objectAtIndex:n]];

		[a_result addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
							 [styled_name autorelease], @"styleName", 
							 cname, @"className", nil]];
		n++;
	}
	return a_result;
}

- (void)setStyleNamesAndCSSClassNames:(NSArray *)dictArray
{
	NSArray *class_names = [dictArray valueForKey:@"className"];
	[[NSUserDefaults standardUserDefaults] setObject:class_names forKey:@"CSSClassNames"];
}

- (void)awakeFromNib
{
	NSWindow *a_window = [self window];
	[a_window center];
	[a_window setFrameUsingName:frameName];	
}

-(void)windowWillClose:(NSNotification *)notification
{
	[[self window] saveFrameUsingName:frameName];
}

- (IBAction)generateCSS:(id)sender
{
	[[ASHTMLController sharedASHTMLController] generateCSS:sender];
}
@end
