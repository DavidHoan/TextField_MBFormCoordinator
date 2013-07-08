#import "MBTextFieldCoordinator.h"

@interface MBTextFieldCoordinator () <UITextFieldDelegate>

@end

@implementation MBTextFieldCoordinator
{
    NSArray *_textFields;
}

+ (instancetype)newWithDelegate:(id<MBTextFieldCoordinatorDelegate>)delegate
{
    MBTextFieldCoordinator *chainer = [MBTextFieldCoordinator new];
    chainer.delegate = delegate;
    return chainer;
}

- (void)enumerateTextFields:(void(^)(UITextField *textField, NSString *text, MBTextFieldValidationType type))block
{
    for(UITextField *textField in _textFields) {
        block(textField, textField.text, [self validationTypeForTextField:textField]);
    }
}

- (void)populateTextFieldsWithValues:(NSArray*)values
{
    [_textFields enumerateObjectsUsingBlock:^(UITextField *textField, NSUInteger idx, BOOL *stop) {
        textField.text = values[idx];
    }];
}

- (UITextField*)textFieldForValidationType:(MBTextFieldValidationType)type
{
    NSMutableArray *fields = [NSMutableArray new];
    for(UITextField *textField in _textFields) {
        if([self validationTypeForTextField:textField] == type) {
            [fields addObject:textField];
        }
    }
    
    return fields.count == 1 ? fields.lastObject : nil;
}

- (NSString*)valueForTextFieldWithType:(MBTextFieldValidationType)type
{
    return [[self textFieldForValidationType:type] text];
}

static NSString *OrderKey = @"MBTextFieldChainerOrderKey";
static NSString *ErrorKey = @"MBTextFieldChainerErrorKey";
static NSString *ValidationTypeKey = @"MBTextFieldChainerValidationTypeKey";

- (void)chainTextFields:(NSArray*)textFields finishType:(UIReturnKeyType)type
{
    [textFields enumerateObjectsUsingBlock:^(UITextField *field, NSUInteger index, BOOL *stop) {
        [field setDynamicValue:@(index) forKey:OrderKey];
        if(index == textFields.count - 1) {
            [field setReturnKeyType:type];
        } else {
            [field setReturnKeyType:UIReturnKeyNext];
        }
        field.delegate = self;
        MBTextFieldValidationType validationType = [self.delegate validationTypeForTextField:field atIndex:index];
        MBTextFieldValidationError *error = [self.delegate validationErrorForTextField:field
                                                                         validatonType:validationType atIndex:index];
        [field setDynamicValue:error forKey:ErrorKey];
        [field setDynamicValue:@(validationType) forKey:ValidationTypeKey];

    }];
    _textFields = textFields;
}

- (void)makeActiveTextFieldAfterTextField:(UITextField*)textField
{
    NSInteger nextIndex = [[textField getDynamicValueForKey:OrderKey] integerValue] + 1;
    [[_textFields safeObjectAtIndex:nextIndex] becomeFirstResponder];
}

- (MBTextFieldValidationError*)errorForTextField:(UITextField*)textField
{
    return [textField getDynamicValueForKey:ErrorKey];
}

- (MBTextFieldValidationType)validationTypeForTextField:(UITextField*)textField
{
    return [[textField getDynamicValueForKey:ValidationTypeKey] integerValue];
}

- (BOOL)validateTextField:(UITextField*)textField notifyDelegate:(BOOL)notify
{
    NSString *text = textField.text;
    NSInteger index = [_textFields indexOfObject:textField];
    BOOL didFail = NO;
    MBTextFieldValidationType type = [self validationTypeForTextField:textField];
    switch (type)
    {
        case MBTextFieldValidationTypeEmail:
            if(text.length && [text isValidEmail] == NO)
                didFail = YES;
            break;
            
        case MBTextFieldValidationTypeEmailConfirmation: {
            UITextField *emailTextField = [self textFieldForValidationType:MBTextFieldValidationTypeEmail];
            if([emailTextField.text isEqualToString:textField.text] == NO)
                didFail = YES;
            break;
        }
        
        case MBTextFieldValidationTypeLetters:
        case MBTextFieldValidationTypeLastName:
        case MBTextFieldValidationTypeName:
            if([text containsOnlyLetters] == NO)
                didFail = YES;
            break;
        
        case MBTextFieldValidationTypeNumbers:
            if([text containsOnlyNumbers] == NO)
                didFail = YES;
            break;
            
        case MBTextFieldValidationTypeNumbersAndLetters:
            if([text containsOnlyNumbersAndLetters] == NO)
                didFail = YES;
            break;
            
        case MBTextFieldValidationTypeNone:
            return YES;
    }
   
    if(didFail) {
        if(notify) {
            [self resignAllTextFields];
            [self.delegate validationDidFailForTextfield:textField
                                                 atIndex:index
                                               withError:[self errorForTextField:textField]];
        }
        return NO;
    }
    return YES;
}

- (void)resignAllTextFields
{
    for(UITextField *field in _textFields) {
        if(field.isFirstResponder)
           [field resignFirstResponder];
    }
}

- (BOOL)validateAllTextFieldsWithInvalidBlock:(MBValidationBlock)invalidBlock
{
    __block NSMutableArray *invalidFields = [NSMutableArray new];
    __block NSMutableArray *invalidErrors = [NSMutableArray new];
    [_textFields enumerateObjectsUsingBlock:^(UITextField *field, NSUInteger index, BOOL *stop) {
        if(![self validateTextField:field notifyDelegate:NO]) {
            [invalidFields addObject:field];
            [invalidErrors addObject:[self errorForTextField:field]];
        }
    }];
    
    if(invalidFields.count > 0) {
        invalidBlock(invalidFields, invalidErrors);
        return NO;
    }
    return YES;
}

#pragma mark - UITextField Delegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if([self validateTextField:textField notifyDelegate:YES])
        [self makeActiveTextFieldAfterTextField:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end

@implementation MBTextFieldValidationError

+ (instancetype)errorWithName:(NSString*)name description:(NSString*)desc
{
    MBTextFieldValidationError * error = [MBTextFieldValidationError new];
    error.name = name;
    error.desc = desc;
    return error;
}

+ (instancetype)errorByAppendingErrors:(NSArray*)errors withTitleSeparator:(NSString*)titleSep descSeparator:(NSString*)descSep
{
    NSMutableString *name = [NSMutableString new];
    NSMutableString *desc = [NSMutableString new];
    [errors enumerateObjectsUsingBlock:^(MBTextFieldValidationError *error, NSUInteger index, BOOL *stop) {
        if(index != 0) {
            [name appendString:titleSep];
            [desc appendString:descSep];
        }
        [name appendString:error.name];
        [desc appendString:error.desc];
    }];
    return [MBTextFieldValidationError errorWithName:name description:desc];
}

@end