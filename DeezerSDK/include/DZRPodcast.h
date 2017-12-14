//
//  DZRPodcast.h
//  Deezer
//
//  Created by Jonathan Benay on 25/09/2015.
//  Copyright © 2015 Deezer. All rights reserved.
//

#import "DZRObject.h"

/*!
 A class representing a podcast in Deezer's model.
 
 Please refer to the documentation of [Deezer's web services for podcasts](http://developers.deezer.com/api/podcast). for
 more information.
 */
@interface DZRPodcast : DZRObject <DZRPlayable, DZRIllustratable>
@end
