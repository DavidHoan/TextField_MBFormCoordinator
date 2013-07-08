##MBTextFieldCoordinator
Easily chain and validate text fields.

###Example

```objective-c

- (void)viewDidLoad 
{
    chainer = [MBTextFieldCoordinator newWithDelegate:self];
    [chainer chainTextFields:@[self.firstNameField, self.lastNameField, self.emailField, self.confirmEmailField] finishType:UIReturnKeyJoin];
    [self.firstNameField becomeFirstResponder];
}

- (void)signUpPressed
{
    MBValidationBlock block = ^(NSArray *invalidTextFields, NSArray *respectiveErrors) {
        MBTextFieldValidationError *error = [MBTextFieldValidationError
                                             errorByAppendingErrors:respectiveErrors
                                             withTitleSeparator:@", "
                                             descSeparator:@"\n"];
        [self showAlertForError:error];
    };
    
    if([chainer validateAllTextFieldsWithInvalidBlock:block] == NO) {
        return;
    }
    
    User *user = [User currentUser];
    [user setFirstName:[chainer valueForTextFieldWithType:MBTextFieldValidationTypeName]
              lastName:[chainer valueForTextFieldWithType:MBTextFieldValidationTypeLastName]];
    [user setEmail:[chainer valueForTextFieldWithType:MBTextFieldValidationTypeEmail]];
	
	//...
}

#pragma mark - Chainer Delegate

- (MBTextFieldValidationType)validationTypeForTextField:(UITextField *)field atIndex:(NSUInteger)index
{
    switch (index) {
        case 0:
            return MBTextFieldValidationTypeName;
        case 1:
            return MBTextFieldValidationTypeLastName;
        case 2:
            return MBTextFieldValidationTypeEmail;
        case 3:
            return MBTextFieldValidationTypeEmailConfirmation;
    }
    return MBTextFieldValidationTypeNone;
}

- (MBTextFieldValidationError*)validationErrorForTextField:(UITextField *)field validatonType:(MBTextFieldValidationType)type atIndex:(NSUInteger)index
{
    if(type == MBTextFieldValidationTypeEmail)
        return [MBTextFieldValidationError errorWithName:@"Invalid Email"
                                             description:@"The email you entered is invalid."];
    else if(type == MBTextFieldValidationTypeEmailConfirmation)
        return [MBTextFieldValidationError errorWithName:@"Nonmatching emails"
                                             description:@"The emails you entered do not match."];
    else if(type == MBTextFieldValidationTypeName)
        return [MBTextFieldValidationError errorWithName:@"Invalid Name"
                                             description:@"The name you entered contains invalid characters"];
    else if(type == MBTextFieldValidationTypeLastName)
        return [MBTextFieldValidationError errorWithName:@"Invalid Last Name"
                                             description:@"The last name you entered contains invalid characters."];
    return nil;
}

- (void)validationDidFailForTextfield:(UITextField *)textField atIndex:(NSUInteger)index withError:(MBTextFieldValidationError *)error
{
    [self showAlertForError:error];
}

- (void)showAlertForError:(MBTextFieldValidationError*)error
{
    [[MBFlatAlertView alertWithTitle:error.name detailText:error.desc cancelTitle:@"Ok" cancelBlock:nil] addToDisplayQueue];
}

```