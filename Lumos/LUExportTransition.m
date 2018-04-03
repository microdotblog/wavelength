//
//  LUExportTransition.m
//  Wavelength
//
//  Created by Manton Reece on 4/3/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUExportTransition.h"

#import "LUExportController.h"

@implementation LUExportTransition

- (nullable id <UIViewControllerAnimatedTransitioning>) animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
	if ([presented isKindOfClass:[LUExportController class]]) {
		return self;
	}
	else {
		return nil;
	}
}

- (nullable id <UIViewControllerAnimatedTransitioning>) animationControllerForDismissedController:(UIViewController *)dismissed
{
	if ([dismissed isKindOfClass:[LUExportController class]]) {
		return self;
	}
	else {
		return nil;
	}
}

- (NSTimeInterval) transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext
{
	return 0.3;
}

- (void) animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
	UIView* container_view = [transitionContext containerView];
	UIViewController* from_controller = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIViewController* to_controller = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	
	if ([to_controller isKindOfClass:[LUExportController class]]) {
		[container_view addSubview:to_controller.view];
		CGRect r = to_controller.view.frame;
	//	r.origin.y = r.origin.y + RFStatusBarHeight() + 44;
		to_controller.view.frame = r;
		to_controller.view.alpha = 0.0;
		
		[UIView animateWithDuration:0.3 animations:^{
			to_controller.view.alpha = 1.0;
		} completion:^(BOOL finished) {
			[transitionContext completeTransition:YES];
		}];
	}
	else if ([from_controller isKindOfClass:[LUExportController class]]) {
		[UIView animateWithDuration:0.3 animations:^{
			from_controller.view.alpha = 0.0;
		} completion:^(BOOL finished) {
			[transitionContext completeTransition:YES];
		}];
	}
}

@end
