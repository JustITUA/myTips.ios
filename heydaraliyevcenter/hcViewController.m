//
//  hcViewController.m
//  heydaraliyevcenter
//
//  Created by Anton Rogachevskiy on 6/11/14.
//  Copyright (c) 2014 JustIT. All rights reserved.
//

#import "hcViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface hcViewController ()
@property (weak, nonatomic) IBOutlet UIButton *networkTestButton;
@property (weak, nonatomic) IBOutlet UISlider *fontSizeSlider;

@end

@implementation hcViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Actions

- (IBAction)networkTestPressed:(id)sender {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[hcAPIClient sharedClient] testWithCompletion:^(BOOL success, NSString * message) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (success) {
            UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"" message:@"Готово" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [errorView show];
        }
        else
        {
            UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(message, nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [errorView show];
        }
    }];
    
}


- (IBAction)fontSizeSliderValueChanged:(id)sender {
    
}


- (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;
{
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (IBAction)screenshotButtonClicked:(id)sender {
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(self.view.bounds.size);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    image = [self imageWithImage:image scaledToSize:CGSizeMake(480, 846)];
    
    NSData * data = UIImagePNGRepresentation(image);
    
    [[hcAPIClient sharedClient] uploadScreenshot:data];

}


@end
