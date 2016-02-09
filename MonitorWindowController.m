#import "MonitorWindowController.h"

@implementation MonitorWindowController

@synthesize contentType;
@synthesize content;

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
	[[self sharedWindowController] setContent:string type:type];
}

- (void)dealloc
{
	self.contentType = nil;
	self.content = nil;
	[super dealloc];
}

- (void)setContent:(NSString *)string type:(NSString *)type
{
	[self setContent:string];
	[self setContentType:type];
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

/*
- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode 
				contextInfo:(void *)contextInfo
{
	if (returnCode != NSOKButton) return;
	NSError *error = nil;
	NSString *string = [monitorTextView string];
	NSURL *an_url = [sheet URL];
	[string writeToURL:an_url
			 atomically:NO encoding:NSUTF8StringEncoding
									error:&error];
	if (!error) return;
	[sheet orderOut:self];
	NSAlert *alert = [NSAlert alertWithError:error];
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:nil
						contextInfo:nil];
}
*/

- (void)printDocument:(id)sender
{
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:monitorTextView];
    [printOperation runOperationModalForWindow: [self window] delegate: nil didRunSelector: NULL contextInfo:
	 NULL];
}

- (void)saveDocument:(id)sender
{
	NSString *type = [self contentType];
	if (!type) return;
	NSSavePanel *save_panel = [NSSavePanel savePanel];
	[save_panel setAllowedFileTypes:[NSArray arrayWithObject:type]];
	[save_panel setCanSelectHiddenExtension:YES];
    [save_panel setNameFieldStringValue:[@"Untitled" stringByAppendingPathExtension:type]];
    
    [save_panel beginSheetModalForWindow:[self window]
                       completionHandler:^(NSInteger result)
     {
         if (result != NSOKButton) return;
         NSError *error = nil;
         NSString *string = [monitorTextView string];
         NSURL *an_url = [save_panel URL];
         [string writeToURL:an_url
                 atomically:NO encoding:NSUTF8StringEncoding
                      error:&error];
         if (!error) return;
         [save_panel orderOut:self];
         NSAlert *alert = [NSAlert alertWithError:error];
         [alert beginSheetModalForWindow:[self window]
                           modalDelegate:self
                          didEndSelector:nil
                             contextInfo:nil];
     }];
}

- (IBAction)copyAll:(id)sender
{
	NSString *type = [self contentType];
	if (!type) return;
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	NSString *actual_type = NSStringPboardType;
	NSArray *types = [NSArray arrayWithObject:actual_type];
	[pboard declareTypes:types owner:nil];
	[pboard setString:[self content] forType:actual_type];
}

@end
