#import "Note.h"
#import "NoteTopBar.h"

@interface NoteViewController : UIViewController <UITextViewDelegate, ButtonActionDelegate>

@property (nonatomic) BOOL isEditing;
@property (nonatomic) BOOL isLocked;
@property (nonatomic, strong) Note *noteView;

- (id)initWithPrefs:(HBPreferences *)preferences screenSize:(CGSize)size useButtonHiding:(BOOL)useButtonHiding;

@end