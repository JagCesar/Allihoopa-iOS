#import "ModalEditor.h"

#import "../Allihoopa+Internal.h"

@interface AHAModalEditor () <UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UITextView* textEditor;
@property (strong, nonatomic) IBOutlet UIView* buttonPlaceholder;
@property (strong, nonatomic) IBOutlet UILabel* characterCountLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* bottomConstraint;
@property (strong, nonatomic) IBOutlet UIButton* doneButton;
@property (strong, nonatomic) IBOutlet UIButton* cancelButton;

@end

@implementation AHAModalEditor {
	NSInteger _maxLength;

	NSString* _title;
	NSString* _initialText;
	UIFont* _textFont;
	BOOL _requiresNonEmptyText;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
		NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

		[nc addObserver:self
			   selector:@selector(keyboardWillShow:)
				   name:UIKeyboardWillShowNotification
				 object:nil];
		[nc addObserver:self
			   selector:@selector(keyboardWillShow:)
				   name:UIKeyboardDidShowNotification
				 object:nil];
		[nc addObserver:self
			   selector:@selector(keyboardWillHide:)
				   name:UIKeyboardWillHideNotification
				 object:nil];
	}

	return self;
}

- (void)dealloc {
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

	[nc removeObserver:self];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
	NSAssert(_title != nil, @"Must have set title");
	NSAssert(_initialText != nil, @"Must have initial text");

	_textEditor.textContainer.lineFragmentPadding = 0;
	_titleLabel.text = _title;
	_textEditor.text = _initialText;
	_textEditor.font = _textFont;

	[self updateCharacterCountLabel];
}

- (void)viewWillAppear:(__unused BOOL)animated {
	[_textEditor becomeFirstResponder];
}

- (void)viewWillDisappear:(__unused BOOL)animated {
	[_textEditor resignFirstResponder];
}

#pragma mark - Public API

- (NSString *)text {
	NSAssert(_textEditor != nil, @"View must be loaded");

	return _textEditor.text;
}

- (void)setTitle:(NSString *)title maxLength:(NSInteger)maxLength text:(NSString *)text style:(UIFont *)font requiresNonEmptyText:(BOOL)requiresNonEmptyText {
	NSAssert(title != nil, @"Title must be set");
	NSAssert(text != nil, @"Text must be set");
	NSAssert(maxLength > 0, @"Max length must be positive");
	NSAssert(font != nil, @"Style must be set");

	_initialText = text;
	_title = title;
	_maxLength = maxLength;
	_textFont = font;
	_requiresNonEmptyText = requiresNonEmptyText;
}

#pragma mark - Private API

- (void)updateCharacterCountLabel {
	NSAssert(_maxLength > 0, @"Max length must be positive");
	NSAssert(_textEditor != nil, @"View must be loaded");
	_characterCountLabel.text = [NSString stringWithFormat:@"%i",
								 (int)(_maxLength - (NSInteger)_textEditor.text.length)];
}

#pragma mark - Keyboard notifications

- (void)updateKeyboardFromNotification:(NSNotification*)notification {
	NSNumber* animationCurveValue = notification.userInfo[UIKeyboardAnimationCurveUserInfoKey];
	NSNumber* animationDurationValue = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];

	UIViewAnimationCurve animationCurve = animationCurveValue.integerValue;
	CGFloat animationDuration = (CGFloat)animationDurationValue.doubleValue;

	[UIView animateWithDuration:animationDuration
						  delay:0
						options:(enum UIViewAnimationOptions)animationCurve << 16
					 animations:^{
						 [self.view layoutIfNeeded];
					 } completion:nil];
}

- (void)keyboardWillShow:(NSNotification*)notification {
	NSValue* frameEndValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
	CGRect frame =  frameEndValue.CGRectValue;

	CGRect localFrame = [self.view convertRect:frame fromView:nil];

	_bottomConstraint.constant = (CGFloat)fmax(CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(localFrame), 0);
	[self updateKeyboardFromNotification:notification];
}

- (void)keyboardWillHide:(NSNotification*)notification {
	_bottomConstraint.constant = 0;
	[self updateKeyboardFromNotification:notification];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    if (_requiresNonEmptyText) {
        NSString* trimmed = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        _doneButton.enabled = trimmed.length > 0;
    }
	[self updateCharacterCountLabel];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	NSString* newText = [textView.text stringByReplacingCharactersInRange:range withString:text];

	return [newText lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 4 <= (NSUInteger)_maxLength;
}

@end
