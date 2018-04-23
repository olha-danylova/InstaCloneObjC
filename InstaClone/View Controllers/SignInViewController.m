
#import "SignInViewController.h"
#import "AlertViewController.h"
#import "Backendless.h"

#define APP_ID @"61AE8EEB-EA13-15FB-FF48-9197C8FD0500"
#define API_KEY @"77CCF20A-A5AB-FF09-FFFC-710027274900"
#define HOST_URL @"http://api.backendless.com"

@implementation SignInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.emailField.delegate = self;
    self.passwordField.delegate = self;
    self.emailField.tag = 0;
    self.passwordField.tag = 1;
    
    backendless.hostURL = HOST_URL;
    [backendless initApp:APP_ID APIKey:API_KEY];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    UITextField *nextTextField = [textField.superview viewWithTag:textField.tag + 1];
    if (nextTextField) {
        [nextTextField becomeFirstResponder];
    }
    else {
        [textField resignFirstResponder];
    }
    return NO;
}

- (IBAction)pressedSignIn:(id)sender {
    if (self.emailField.text.length > 0 && self.passwordField.text > 0) {
        NSString *email = self.emailField.text;
        NSString *password = self.passwordField.text;
        [backendless.userService setStayLoggedIn:YES];
        [backendless.userService login:email
                              password:password
                              response:^(BackendlessUser *user) {
                                  [self performSegueWithIdentifier:@"showTabBar" sender:nil];
                              } error:^(Fault *fault) {
                                  [alertViewController showErrorAlert:fault.faultCode title:nil message:fault.message target:self];
                              }];        
    }
    else {
        [alertViewController showErrorAlert:nil title:@"Invalid email or password" message:@"Please make sure you've entered your email and password correctly" target:self];
    }
}

- (IBAction)pressedRegister:(id)sender {
    [self performSegueWithIdentifier:@"showSignUp" sender:nil];
}

-(IBAction)unwindToSignInVC:(UIStoryboardSegue *)segue {
}

@end
