//
//  BusStopCellBaseClass.m
//  GRTEasyGo
//
//  Created by Yuanfeng on 11-07-06.
//  Copyright 2011 Elton(Yuanfeng) Gao. All rights reserved.
//

#import "BusStopCellBaseClass.h"
#import "Stop.h"
#import "BusRoute.h"
#import "FavouriteStopsCentralManager.h"

#define INSET_LEFT 30
#define NAME_WIDTH 280
#define EXTRA_INFO_WIDTH 280
#define NAME_FONT @"Helvetica"
#define NAME_FONT_SIZE 20.0
#define EXTRA_INFO_FONT_SIZE 14.0

#define BUTTON_SIZE_WIDTH 280
#define BUTTON_SIZE_HEIGHT 15

#define ADD_FAV_ALERT_TAG 0
#define REMOVE_FAV_ALERT_TAG 1

@implementation BusStopCellBaseClass

@synthesize name = name_, extraInfo = extraInfo_;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        name_ = [[UILabel alloc] initWithFrame:CGRectMake(INSET_LEFT, 2, NAME_WIDTH, NAME_HEIGHT)];
        name_.backgroundColor = [UIColor clearColor];
        name_.font = [UIFont boldSystemFontOfSize:NAME_FONT_SIZE];
        [self.contentView addSubview:name_];
        
        extraInfo_ = [[UILabel alloc] initWithFrame:CGRectMake(INSET_LEFT, NAME_HEIGHT+4, EXTRA_INFO_WIDTH, EXTRA_INFO_HEIGHT)];
        extraInfo_.font = [UIFont systemFontOfSize:EXTRA_INFO_FONT_SIZE];
        extraInfo_.textAlignment = UITextAlignmentLeft;
        extraInfo_.textColor = [UIColor grayColor];
        extraInfo_.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:extraInfo_];
        
        fav_ = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, INSET_LEFT, INSET_LEFT)];
        fav_.center = CGPointMake(fav_.center.x, self.contentView.center.y);
        fav_.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
        [fav_ setImage:[UIImage imageNamed:@"star_grey"] forState:UIControlStateNormal];
        [fav_ setImage:[UIImage imageNamed:@"star_yellow"] forState:UIControlStateHighlighted];
        [fav_ setImage:[UIImage imageNamed:@"star_yellow"] forState:UIControlStateSelected];
        [fav_ addTarget:self action:@selector(favPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:fav_];
        
        availableRoutes_ = [[UILabel alloc] initWithFrame:CGRectMake(INSET_LEFT, NAME_HEIGHT+EXTRA_INFO_HEIGHT+8, BUTTON_SIZE_WIDTH, BUTTON_SIZE_HEIGHT)];
        availableRoutes_.font = [UIFont systemFontOfSize:EXTRA_INFO_FONT_SIZE];
        availableRoutes_.backgroundColor = [UIColor clearColor];
        availableRoutes_.textAlignment = UITextAlignmentLeft;
        availableRoutes_.text = @"";
        [self.contentView addSubview:availableRoutes_];
        
        UIImage *cellBg = [UIImage imageNamed:@"cell_bg"];
        cellBg = [cellBg stretchableImageWithLeftCapWidth:0 topCapHeight:0];
        self.backgroundView = [[UIImageView alloc] initWithImage:cellBg];
    }
    return self;
}

- (void)toggleFavButtonStatus {
    isStopFav_ = !isStopFav_;
    fav_.selected = !fav_.selected;
}

- (void)initCellInfoWithStop:(Stop*)stop {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    stop_ = stop;
    
    if( [[FavouriteStopsCentralManager sharedInstance] isFavouriteStop:stop] ) {
        isStopFav_ = YES;
        fav_.selected = YES;
        
        NSString* result = [[FavouriteStopsCentralManager sharedInstance] getCustomNameForStop:stop];
        if( [result length] != 0 ) {
            //if there is indeed a custom name, make it as main title
            name_.text = result;
            extraInfo_.text = [NSString stringWithFormat:@"%@, %@", stop.stopName, stop.stopID];
        } else {
            //otherwise, still put original stop name
            //TODO refractor this method(duplication)
            name_.text = stop.stopName;
            extraInfo_.text = [NSString stringWithFormat:@"Stop Number: %@", stop.stopID];
        }
    } else {
        isStopFav_ = NO;
        fav_.selected = NO;
        
        name_.text = stop.stopName;
        extraInfo_.text = [NSString stringWithFormat:@"Stop Number: %@", stop.stopID];
    }
}

- (void)refreshRoutesInCellWithSeconds:(NSTimeInterval) seconds {
    //when we get the signal on number of seconds that has passed, we tell this to every route
    //and then let sub classes to decide how to update the time
    for( BusRoute* route in stop_.busRoutes ) {
        [route refreshCountDownWithSeconds:seconds];
    }
    
    int numRoutesToDisplay = [stop_ numberOfBusRoutes];
    //bool moreThanTwoRoues = numRoutesToDisplay>2 ? YES:NO;
    //numRoutesToDisplay = numRoutesToDisplay>=3 ? 3:numRoutesToDisplay;
    
    if (numRoutesToDisplay != 0) {
        availableRoutes_.text = @"Bus routes: ";
        for (int i=0; i<numRoutesToDisplay; i++) {
            //        if( i != 2 ) {
            //            UILabel* label = [routesAndTimes_ objectAtIndex:i];
            //            BusRoute* route = [stop_.busRoutes objectAtIndex:i];
            //            
            //            //get the first arrival time
            //            label.text = [route getFirstArrivalTime];
            //        } else if( moreThanTwoRoues ) {
            //            UILabel* label = [routesAndTimes_ objectAtIndex:i];
            //            [label setText:@"••••••"];
            //        } else {
            //            UILabel* label = [routesAndTimes_ objectAtIndex:i];
            //            label.text = @"";
            //        }
            BusRoute* route = [stop_.busRoutes objectAtIndex:i];
            NSString* comma = (i==[stop_.busRoutes count]-1)? @"" :@",";
            availableRoutes_.text = [NSString stringWithFormat:@"%@%@%@ ", availableRoutes_.text, route.shortRouteNumber, comma];
        }
    } else {
        availableRoutes_.text = @"No bus route available.";
    }
}

#pragma mark - fav button delegate
- (void)favPressed {
    if( !isStopFav_ ) {
        [self toggleFavButtonStatus];
        
        alert_ = [[UIAlertView alloc] initWithTitle:@"Favourite Added!" 
                                             message:@"You can give a nickname:\n\n\n" 
                                            delegate:self 
                                   cancelButtonTitle:@"Skip" otherButtonTitles:nil];
        alert_.tag = ADD_FAV_ALERT_TAG;
        
        customNameField_ = [[UITextField alloc] initWithFrame:CGRectMake(14,77,254,30)];
        customNameField_.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 13, 10)];
        customNameField_.borderStyle = UITextBorderStyleBezel;
        customNameField_.clearButtonMode = UITextFieldViewModeWhileEditing;
        customNameField_.leftViewMode = UITextFieldViewModeAlways;
        customNameField_.layer.cornerRadius = 5.0f;
        customNameField_.font = [UIFont systemFontOfSize:18];
        customNameField_.backgroundColor = [UIColor whiteColor];
        customNameField_.keyboardAppearance = UIKeyboardAppearanceAlert;
        customNameField_.delegate = self;
        [customNameField_ setSelected:YES];
        customNameField_.placeholder = @"Enter a nickname here...";
        
        [alert_ setTransform:CGAffineTransformMakeTranslation(0,109)];
        [alert_ show];
        
        [alert_ addSubview:customNameField_];
    } else {
        alert_ = [[UIAlertView alloc] initWithTitle:@"Remove Favourite Stop" 
                                             message:@"Are you sure to do so?" 
                                            delegate:self 
                                   cancelButtonTitle:@"Cancel" otherButtonTitles:@"Confirm", nil];
        alert_.tag = REMOVE_FAV_ALERT_TAG;
        
        [alert_ show];
    }
}

#pragma mark - Text Field Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if( [[textField text] length] != 0 ) {
        [alert_ dismissWithClickedButtonIndex:0 animated:YES];
    } else {
        textField.placeholder = @"Please enter a name!";
    }
    return YES;
}

#pragma mark - Alert View Delegate

- (void)didPresentAlertView:(UIAlertView *)alertView {
    [customNameField_ becomeFirstResponder];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    [customNameField_ resignFirstResponder];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if( alertView.tag == ADD_FAV_ALERT_TAG ) {
        //save the stop to userDefault
        [[FavouriteStopsCentralManager sharedInstance] addFavoriteStop:stop_ Name:[customNameField_ text]];
        
        //refresh the cell's name (replace name with custom name)
        [self initCellInfoWithStop:stop_];
        
        //post notification so that fav tab gets refreshed table
        [[NSNotificationCenter defaultCenter] postNotificationName:kFavStopArrayDidUpdate object:nil];
        
    } else if( alertView.tag == REMOVE_FAV_ALERT_TAG && buttonIndex == 1 ){
        //user confirmed to delete this fav
        [self toggleFavButtonStatus];
        [self setNeedsLayout]; //if this is not called, button will not become grey
        
        [[FavouriteStopsCentralManager sharedInstance] deleteFavoriteStop:stop_];
        
        //refresh the cell's name (remove custom name)
        [self initCellInfoWithStop:stop_];
        
        //post notification so that fav tab gets refreshed table
        [[NSNotificationCenter defaultCenter] postNotificationName:kFavStopArrayDidUpdate object:nil];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    // Configure the view for the selected state
    [super setSelected:selected animated:animated];
}

#pragma mark - Memory Management

- (void)dealloc
{
}

@end
