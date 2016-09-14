//
//  VideoCell.m
//  MyPlayer
//
//  Created by SU on 16/8/23.
//  Copyright © 2016年 SU. All rights reserved.
//

#import "VideoCell.h"
#import "VideoModel.h"

@implementation VideoCell

- (void)setModel:(VideoModel *)model
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.titleLabel.text = model.title;
    self.descriptionLabel.text = model.descriptionDe;
    [self.backgroundIV sd_setImageWithURL:[NSURL URLWithString:model.cover] placeholderImage:[UIImage imageNamed:@"logo"]];
    if (model.playCount > 1000) {
        self.countLabel.text = [NSString stringWithFormat:@"%ld.%ld万",model.playCount/10000,model.playCount%10000/100];
    }
    else{
        self.countLabel.text = [NSString stringWithFormat:@"%ld",model.playCount];
    }
    
    self.timeDurationLabel.text = [model.ptime substringWithRange:NSMakeRange(12, 4)];
}
@end
