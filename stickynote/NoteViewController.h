#import "Note.h"

@interface NoteViewController : UIViewController <UITextViewDelegate>

@property (nonatomic, strong) Note *noteView;

- (id)initWithNoteSize:(CGSize)size;

@end