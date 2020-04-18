#import "Note.h"

@interface NoteViewController : UIViewController

@property (nonatomic, strong) Note *noteView;

- (id)initWithDefaults:(NSDictionary *)defaults;

@end