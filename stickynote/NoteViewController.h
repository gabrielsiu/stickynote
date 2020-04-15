#import "Note.h"

@interface NoteViewController : UIViewController <UITextViewDelegate>

@property (nonatomic, strong) Note *noteView;

- (id)initWithDefaults:(NSDictionary *)defaults;

@end