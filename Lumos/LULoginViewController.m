//
//  LULoginViewController.m
//  Lumos
//
//  Created by Jonathan Hays on 3/22/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LULoginViewController.h"
#import "RFClient.h"
#import "UUAlert.h"

@interface LULoginViewController ()<UITextFieldDelegate>

@end

@implementation LULoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction) onCancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self beginMicropubProcessing];
	[textField resignFirstResponder];
	
	return NO;
}

- (void) beginMicropubProcessing
{
 	RFClient* client = [[RFClient alloc] initWithPath:@"/account/signin"];
	NSDictionary* args = @
    {
		@"email": self.loginField.text,
        @"app_name" : @"Coastal",
        @"redirect_url" : @"https://sunlit.io/microblog/redirect/"
	};
	
	[client postWithParams:args completion:^(UUHttpResponse* response)
    {
        [UUAlertViewController uuShowOneButtonAlert:nil message:@"Email sent! Check your email on this device and tap the \"Open with Wavelength\" button." button:@"OK" completionHandler:^(NSInteger buttonIndex)
        {
			[self onCancel:self];
        }];
    }];

}


@end
