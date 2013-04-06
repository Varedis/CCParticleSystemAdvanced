//
//  LayeredParticleSystem.h
//  LayeredParticleSystem
//
//  Created by Robert Scott on 10/02/2013.
//  Copyright 2013 Unseen-Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#import "SpriteSheetParticleSystem.h"

@interface LayeredParticleSystem : CCNode {
    
}

-(id)initWithPlist:(NSString *)plistFile WithSpriteSheet:(NSString *)spritesheet andString:(NSString *)str count:(int)count;
-(id) initWithPlist:(NSString *)plistFile;
-(id) initWithFullDictionary:(NSDictionary *)fullDict;
-(void) resetAllLayers;
-(void) resetAllOtherLayers:(int)index;
-(void) stopAllLayers;
-(SpriteSheetParticleSystem *) addNewLayer:(NSDictionary *)dict index:(int)index;
-(void) removeLayer:(int)index;
-(SpriteSheetParticleSystem *) removeAndAddLayer:(NSDictionary *)dict index:(int)index;

-(void) setAutoRemoveOnFinish:(BOOL)value;
-(void) setPositionType:(tCCPositionType)value;
-(void) runAction:(CCAction *)action;


@end
