//
//  DZREpisode.h
//  Deezer
//
//  Created by Jonathan Benay on 28/09/2015.
//  Copyright © 2015 Deezer. All rights reserved.
//

#import "DZRObject.h"

/*!
 A class representing a episode in Deezer's model.
 
 Please refer to the documentation of [Deezer's web services for episodes](http://developers.deezer.com/api/episode). for
 more information.
 */
@interface DZREpisode : DZRObject <DZRPlayable, DZRIllustratable, DZRPlayableObject>
@end
