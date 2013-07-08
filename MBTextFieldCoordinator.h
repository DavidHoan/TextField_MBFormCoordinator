#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MBTextFieldValidationType)
{
    MBTextFieldValidationTypeNone,
    MBTextFieldValidationTypeName,
    MBTextFieldValidationTypeLastName,
    MBTextFieldValidationTypeLetters,
    MBTextFieldValidationTypeNumbers,
    MBTextFieldValidationTypeNumbersAndLetters,
    MBTextFieldValidationTypeEmail,
    MBTextFieldValidationTypeEmailConfirmation
};

@interface MBTextFieldValidationError : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *desc;
+ (instancetype)errorWithName:(NSString*)name description:(NSString*)desc;
+ (instancetype)errorByAppendingErrors:(NSArray*)errors withTitleSeparator:(NSString*)titleSep descSeparator:(NSString*)descSep;
@end

@protocol MBTextFieldCoordinatorDelegate <NSObject>
- (MBTextFieldValidationType)validationTypeForTextField:(UITextField*)field atIndex:(NSUInteger)index;
- (MBTextFieldValidationError*)validationErrorForTextField:(UITextField*)field validatonType:(MBTextFieldValidationType)type atIndex:(NSUInteger)index;
- (void)validationDidFailForTextfield:(UITextField*)textField atIndex:(NSUInteger)index withError:(MBTextFieldValidationError*)error;
@end

@interface MBTextFieldCoordinator : NSObject
@property (nonatomic, weak) id<MBTextFieldCoordinatorDelegate> delegate;
+ (instancetype)newWithDelegate:(id<MBTextFieldCoordinatorDelegate>)delegate;
- (void)chainTextFields:(NSArray*)textFields finishType:(UIReturnKeyType)type;
- (void)makeActiveTextFieldAfterTextField:(UITextField*)textField;
- (void)populateTextFieldsWithValues:(NSArray*)values;

// used for unique validation types; if more than one found, returns nil
- (UITextField*)textFieldForValidationType:(MBTextFieldValidationType)type;
- (NSString*)valueForTextFieldWithType:(MBTextFieldValidationType)type;
- (void)enumerateTextFields:(void(^)(UITextField *textField, NSString *text, MBTextFieldValidationType type))block;

typedef void (^MBValidationBlock)(NSArray *invalidTextFields, NSArray *respectiveErrors);
// block is only called if at least one textfield fails validation
- (BOOL)validateAllTextFieldsWithInvalidBlock:(MBValidationBlock)invalidBlock;
- (void)resignAllTextFields;
@end
