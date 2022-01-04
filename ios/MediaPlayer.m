//
//  MediaPlayer.m
//  AppleMusic
//
//  Created by Hien Phung on 5/6/20.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import "MediaPlayer.h"
#import <React/RCTConvert.h>

@implementation RCTConvert (MPMusicPlaybackState)
  RCT_ENUM_CONVERTER(MPMusicPlaybackState, (@{
      @"playbackStateStopped":@(MPMusicPlaybackStateStopped),
      @"playbackStatePlaying": @(MPMusicPlaybackStatePlaying),
      @"playbackStatePaused": @(MPMusicPlaybackStatePaused),
      @"playbackStateInterrupted": @(MPMusicPlaybackStateInterrupted),
      @"playbackStateSeekingForward": @(MPMusicPlaybackStateSeekingForward),
      @"playbackStateSeekingBackward": @(MPMusicPlaybackStateSeekingBackward)}),
  MPMusicPlaybackStateStopped, integerValue)
@end


@implementation MediaPlayer

RCT_EXPORT_MODULE()

- (NSDictionary *)constantsToExport
{
  return @{ @"playbackStateStopped":@(MPMusicPlaybackStateStopped),
  @"playbackStatePlaying": @(MPMusicPlaybackStatePlaying),
  @"playbackStatePaused": @(MPMusicPlaybackStatePaused),
  @"playbackStateInterrupted": @(MPMusicPlaybackStateInterrupted),
  @"playbackStateSeekingForward": @(MPMusicPlaybackStateSeekingForward),
  @"playbackStateSeekingBackward": @(MPMusicPlaybackStateSeekingBackward)};
};

+ (MPMusicPlayerApplicationController*) applicationQueuePlayer
{
    static MPMusicPlayerApplicationController *applicationQueuePlayer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        applicationQueuePlayer = MPMusicPlayerController.applicationQueuePlayer;
    });
    return applicationQueuePlayer;
}

RCT_EXPORT_METHOD(setQueue: (NSArray<NSString*>*)storeIDs)
{
    MPMusicPlayerStoreQueueDescriptor* descriptor = [[MPMusicPlayerStoreQueueDescriptor alloc] initWithStoreIDs:storeIDs];
    [MediaPlayer.applicationQueuePlayer setQueueWithDescriptor:descriptor];
}

RCT_EXPORT_METHOD(getPlaybackState)
{
    [MediaPlayer.applicationQueuePlayer playbackState];
}

RCT_EXPORT_METHOD(play)
{
    [MediaPlayer.applicationQueuePlayer play];
}

RCT_EXPORT_METHOD(pause)
{
    [MediaPlayer.applicationQueuePlayer pause];
}

RCT_EXPORT_METHOD(stop)
{
    [MediaPlayer.applicationQueuePlayer stop];
}

RCT_EXPORT_METHOD(skipToNextItem) {
    [MediaPlayer.applicationQueuePlayer skipToNextItem];
}

RCT_EXPORT_METHOD(skipToPreviousItem) {
    [MediaPlayer.applicationQueuePlayer skipToPreviousItem];
}

RCT_EXPORT_METHOD(skipToBeginning) {
    [MediaPlayer.applicationQueuePlayer skipToBeginning];
}

RCT_EXPORT_METHOD(seek:(double)seconds) {
    MediaPlayer.applicationQueuePlayer.currentPlaybackTime = seconds;
}

RCT_EXPORT_METHOD(getTracks:(NSDictionary *)params successCallback:(RCTResponseSenderBlock)successCallback) {

    NSLog(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));

    NSArray *fields = [RCTConvert NSArray:params[@"fields"]];
    NSDictionary *query = [RCTConvert NSDictionary:params[@"query"]];
    NSString *type  = [RCTConvert NSString:params[@"type"]];

    NSLog(@"query %@", query);

    MPMediaQuery *songsQuery;
    if ( [type isEqual: @"podcasts"] ){
        songsQuery = [MPMediaQuery podcastsQuery];
    }else if ( [type isEqual: @"audiobooks"] ){
        songsQuery = [MPMediaQuery audiobooksQuery];
    //}else if ( [type isEqual: @"compilations"]) {
    //    songsQuery = [MPMediaQuery compilationsQuery];
    //}else if ( [type isEqual: @"composers"] ){
    //    songsQuery = [MPMediaQuery composersQuery];
    }else{
        songsQuery = [MPMediaQuery songsQuery];
    }


    if ([query objectForKey:@"title"] != nil) {
        NSString *searchTitle = [query objectForKey:@"title"];
        [songsQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:searchTitle forProperty:MPMediaItemPropertyTitle comparisonType:MPMediaPredicateComparisonContains]];
    }
    if ([query objectForKey:@"albumTitle"] != nil) {
        NSString *searchAlbumTitle = [query objectForKey:@"albumTitle"];
        [songsQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:searchAlbumTitle forProperty:MPMediaItemPropertyAlbumTitle comparisonType:MPMediaPredicateComparisonContains]];
    }
    if ([query objectForKey:@"albumArtist"] != nil) {
        NSString *searchalbumArtist = [query objectForKey:@"albumArtist"];
        [songsQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:searchalbumArtist forProperty:MPMediaItemPropertyAlbumArtist comparisonType:MPMediaPredicateComparisonContains]];
    }
    if ([query objectForKey:@"artist"] != nil) {
        NSString *searchArtist = [query objectForKey:@"artist"];
        [songsQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:searchArtist forProperty:MPMediaItemPropertyArtist comparisonType:MPMediaPredicateComparisonContains]];
    }
    if ([query objectForKey:@"genre"] != nil) {
        NSString *searchGenre = [query objectForKey:@"genre"];
        [songsQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:searchGenre forProperty:MPMediaItemPropertyGenre comparisonType:MPMediaPredicateComparisonContains]];
    }
    if ([query objectForKey:@"persistentId"] != nil) {
        NSNumber *persistentId = [query objectForKey:@"persistentId"];
        NSNumber  *searchPersistentId = [NSNumber numberWithInteger: [persistentId integerValue]];
        [songsQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:persistentId forProperty:MPMediaItemPropertyPersistentID comparisonType:MPMediaPredicateComparisonContains]];
    }

    NSMutableArray *mutableSongsToSerialize = [NSMutableArray array];

    for (MPMediaItem *song in songsQuery.items) {

        // filterable
        NSString *title = [song valueForProperty: MPMediaItemPropertyTitle]; // filterable
        NSString *albumTitle = [song valueForProperty: MPMediaItemPropertyAlbumTitle]; // filterable
        NSString *albumArtist = [song valueForProperty: MPMediaItemPropertyAlbumArtist]; // filterable
        NSString *genre = [song valueForProperty: MPMediaItemPropertyGenre]; // filterable
        NSString *duration = [song valueForProperty: MPMediaItemPropertyPlaybackDuration];
        NSString *playCount = [song valueForProperty: MPMediaItemPropertyPlayCount];

        if (title == nil) {
            title = @"";
        }
        if (albumTitle == nil) {
            albumTitle = @"";
        }
        if (albumArtist == nil) {
            albumArtist = @"";
        }
        if (genre == nil) {
            genre = @"";
        }
        if (duration == nil) {
            duration = @"0";
        }
        if (playCount == nil) {
            playCount = @"0";
        }

        //        NSString *test = @"1";
        //        int *testId = [test intValue];
        //        Boolean testBool = [test intValue];
        //        NSLog(@"testId %d", testId);
        //        NSLog(@"testBool %d", testBool);


        NSDictionary *songDictionary = [NSMutableDictionary dictionary];

        if (fields == nil) {
            songDictionary = @{@"albumTitle":albumTitle, @"albumArtist": albumArtist, @"duration":[duration isKindOfClass:[NSString class]] ? [NSNumber numberWithInt:[duration intValue]] : duration, @"genre":genre, @"playCount": [NSNumber numberWithInt:[playCount intValue]], @"title": title};
        } else {
            if ([fields containsObject: @"persistentId"]) {
                NSString *persistentId = [song valueForProperty: MPMediaItemPropertyPersistentID];
                if (persistentId == nil) {
                    persistentId = @"0";
                }

                [songDictionary setValue:[NSNumber numberWithInt:[persistentId intValue]] forKey:@"persistentId"];
            }
            if ([fields containsObject: @"albumPersistentId"]) {
                NSString *albumPersistentId = [song valueForProperty: MPMediaItemPropertyAlbumPersistentID];
                if (albumPersistentId == nil) {
                    albumPersistentId = @"0";
                }

                [songDictionary setValue:[NSNumber numberWithInt:[albumPersistentId intValue]] forKey:@"albumPersistentId"];
            }
            if ([fields containsObject: @"artistPersistentId"]) {
                NSString *artistPersistentId = [song valueForProperty: MPMediaItemPropertyArtistPersistentID];
                if (artistPersistentId == nil) {
                    artistPersistentId = @"0";
                }

                [songDictionary setValue:[NSNumber numberWithInt:[artistPersistentId intValue]] forKey:@"artistPersistentId"];
            }
            if ([fields containsObject: @"albumArtistPersistentId"]) {
                NSString *albumArtistPersistentId = [song valueForProperty: MPMediaItemPropertyAlbumArtistPersistentID];
                if (albumArtistPersistentId == nil) {
                    albumArtistPersistentId = @"0";
                }

                [songDictionary setValue:[NSNumber numberWithInt:[albumArtistPersistentId intValue]] forKey:@"albumArtistPersistentId"];
            }
            if ([fields containsObject: @"genrePersistentId"]) {
                NSString *genrePersistentId = [song valueForProperty: MPMediaItemPropertyGenrePersistentID]; // filterable
                if (genrePersistentId == nil) {
                    genrePersistentId = @"0";
                }

                [songDictionary setValue:[NSNumber numberWithInt:[genrePersistentId intValue]] forKey:@"genrePersistentId"];
            }
            if ([fields containsObject: @"composerPersistentId"]) {
                NSString *composerPersistentId = [song valueForProperty: MPMediaItemPropertyComposerPersistentID]; // filterable
                if (composerPersistentId == nil) {
                    composerPersistentId = @"0";
                }

                [songDictionary setValue:[NSNumber numberWithInt:[composerPersistentId intValue]] forKey:@"composerPersistentId"];
            }
            if ([fields containsObject: @"podcastPersistentId"]) {
                NSString *podcastPersistentId = [song valueForProperty: MPMediaItemPropertyPodcastPersistentID];
                if (podcastPersistentId == nil) {
                    podcastPersistentId = @"0";
                }

                [songDictionary setValue:[NSNumber numberWithInt:[podcastPersistentId intValue]] forKey:@"podcastPersistentId"];
            }
            if ([fields containsObject: @"mediaType"]) {
                NSString *mediaType = [song valueForProperty: MPMediaItemPropertyMediaType]; // filterable
                if (mediaType == nil) {
                    mediaType = @"";
                }

                [songDictionary setValue:[NSNumber numberWithInt:mediaType] forKey:@"mediaType"];
            }
            if ([fields containsObject: @"title"]) {
                [songDictionary setValue:[NSString stringWithString:title] forKey:@"title"];
            }
            if ([fields containsObject: @"albumTitle"]) {
                [songDictionary setValue:[NSString stringWithString:albumTitle] forKey:@"albumTitle"];
            }
            if ([fields containsObject: @"artist"]) {
                NSString *artist = [song valueForProperty: MPMediaItemPropertyArtist]; // filterable
                if (artist == nil) {
                    artist = @"";
                }
                [songDictionary setValue:[NSString stringWithString:artist] forKey:@"artist"];
            }
            if ([fields containsObject: @"albumArtist"]) {
                [songDictionary setValue:[NSString stringWithString:albumArtist] forKey:@"albumArtist"];
            }
            if ([fields containsObject: @"genre"]) {
                [songDictionary setValue:[NSString stringWithString:genre] forKey:@"genre"];
            }
            if ([fields containsObject: @"composer"]) {
                NSString *composer = [song valueForProperty: MPMediaItemPropertyComposer]; // filterable
                if (composer == nil) {
                    composer = @"";
                }
                [songDictionary setValue:[NSString stringWithString:composer] forKey:@"composer"];
            }
            if ([fields containsObject: @"duration"]) {
                [songDictionary setValue:[duration isKindOfClass:[NSString class]] ? [NSNumber numberWithInt:[duration intValue]] : duration forKey:@"duration"];
            }
            if ([fields containsObject: @"albumTrackNumber"]) {
                NSString *albumTrackNumber = [song valueForProperty: MPMediaItemPropertyAlbumTrackNumber];
                if (albumTrackNumber == nil) {
                    albumTrackNumber = @"0";
                }
                [songDictionary setValue:[NSNumber numberWithInt:[albumTrackNumber intValue]] forKey:@"albumTrackNumber"];
            }
            if ([fields containsObject: @"albumTrackCount"]) {
                NSString *albumTrackCount = [song valueForProperty: MPMediaItemPropertyAlbumTrackCount];
                if (albumTrackCount == nil) {
                    albumTrackCount = @"0";
                }
                [songDictionary setValue:[NSNumber numberWithInt:[albumTrackCount intValue]] forKey:@"albumTrackCount"];
            }
            if ([fields containsObject: @"discNumber"]) {
                NSString *discNumber = [song valueForProperty: MPMediaItemPropertyDiscNumber];
                if (discNumber == nil) {
                    discNumber = @"0";
                }
                [songDictionary setValue:[NSNumber numberWithInt:[discNumber intValue]] forKey:@"discNumber"];
            }
            if ([fields containsObject: @"discCount"]) {
                NSString *discCount = [song valueForProperty: MPMediaItemPropertyDiscCount];
                if (discCount == nil) {
                    discCount = @"0";
                }
                [songDictionary setValue:[NSNumber numberWithInt:[discCount intValue]] forKey:@"discCount"];
            }
            if ([fields containsObject: @"artwork"]) {
                // http://stackoverflow.com/questions/25998621/mpmediaitemartwork-is-null-while-cover-is-available-in-itunes
                MPMediaItemArtwork *artwork = [song valueForProperty: MPMediaItemPropertyArtwork];
                if (artwork != nil) {
                    // NSLog(@"artwork %@", artwork);
                    UIImage *image = [artwork imageWithSize:CGSizeMake(100, 100)];
                    // http://www.12qw.ch/2014/12/tooltip-decoding-base64-images-with-chrome-data-url/
                    // http://stackoverflow.com/a/510444/185771
                    NSString *base64 = [NSString stringWithFormat:@"%@%@", @"data:image/jpeg;base64,", [self imageToNSString:image]];
                    [songDictionary setValue:base64 forKey:@"artwork"];
                } else {
                    [songDictionary setValue:@"" forKey:@"artwork"];
                }
            }
            if ([fields containsObject: @"lyrics"]) {
                NSString *lyrics = [song valueForProperty: MPMediaItemPropertyLyrics];
                if (lyrics == nil) {
                    lyrics = @"";
                }
                [songDictionary setValue:[NSString stringWithString:lyrics] forKey:@"lyrics"];
            }
            if ([fields containsObject: @"isCompilation"]) {
                NSString *isCompilation = [song valueForProperty: MPMediaItemPropertyIsCompilation]; // filterable
                if (isCompilation == nil) {
                    isCompilation = @"0";
                }
                [songDictionary setValue:[NSNumber numberWithBool:[isCompilation intValue]] forKey:@"isCompilation"];
            }
            /*if ([fields containsObject: @"releaseDate"]) {
             NSString *releaseDate = [song valueForProperty: MPMediaItemPropertyReleaseDate];
             [songDictionary setValue:[NSString stringWithString:releaseDate] forKey:@"releaseDate"];
             }*/
            if ([fields containsObject: @"beatsPerMinute"]) {
                NSString *beatsPerMinute = [song valueForProperty: MPMediaItemPropertyBeatsPerMinute];
                if (beatsPerMinute == nil) {
                    beatsPerMinute = @"0";
                }
                [songDictionary setValue:[NSNumber numberWithInt:[beatsPerMinute intValue]] forKey:@"beatsPerMinute"];
            }
            if ([fields containsObject: @"comments"]) {
                NSString *comments = [song valueForProperty: MPMediaItemPropertyComments];
                if (comments == nil) {
                    comments = @"";
                }
                [songDictionary setValue:[NSString stringWithString:comments] forKey:@"comments"];
            }
            if ([fields containsObject: @"assetUrl"]) {
                NSURL *url = [song valueForProperty: MPMediaItemPropertyAssetURL];
                NSString *assetUrl = url.absoluteString;
                if (assetUrl == nil) {
                    assetUrl = @"";
                }
                [songDictionary setValue:[NSString stringWithString:assetUrl] forKey:@"assetUrl"];
            }
            if ([fields containsObject: @"isCloudItem"]) {
                NSString *isCloudItem = [song valueForProperty: MPMediaItemPropertyIsCloudItem];
                if (isCloudItem == nil) {
                    isCloudItem = @"0";
                }
                [songDictionary setValue:[NSNumber numberWithBool:[isCloudItem intValue]] forKey:@"isCloudItem"];
            }
            if ([fields containsObject: @"playCount"]) {
                [songDictionary setValue:[NSNumber numberWithInt:[playCount intValue]] forKey:@"playCount"];
            }
            if ([fields containsObject: @"skipCount"]) {
                NSString *skipCount = [song valueForProperty: MPMediaItemPropertySkipCount];
                if (skipCount == nil) {
                    skipCount = @"0";
                }
                [songDictionary setValue:[NSNumber numberWithInt:[skipCount intValue]] forKey:@"skipCount"];
            }
            if ([fields containsObject: @"rating"]) {
                NSString *rating = [song valueForProperty: MPMediaItemPropertyRating];
                if (rating == nil) {
                    rating = @"0";
                }
                [songDictionary setValue:[NSNumber numberWithInt:[rating intValue]] forKey:@"rating"];
            }
            /*if ([fields containsObject: @"playedDate"]) {
             NSString *playedDate = [song valueForProperty: MPMediaItemPropertyLastPlayedDate];
             [songDictionary setValue:[NSString stringWithString:playedDate] forKey:@"playedDate"];
             }*/
            if ([fields containsObject: @"userGrouping"]) {
                NSString *userGrouping = [song valueForProperty: MPMediaItemPropertyUserGrouping];
                if (userGrouping == nil) {
                    userGrouping = @"";
                }
                [songDictionary setValue:[NSString stringWithString:userGrouping] forKey:@"userGrouping"];
            }
            /*if ([fields containsObject: @"bookmarkTime"]) {
             NSString *bookmarkTime = [song valueForProperty: MPMediaItemPropertyBookmarkTime];
             if (bookmarkTime == nil) {
             bookmarkTime = @"";
             }
             [songDictionary setValue:[NSNumber numberWithInt:bookmarkTime] forKey:@"bookmarkTime"];
             }*/

            // Aliases
            if ([fields containsObject: @"playbackDuration"]) {
                [songDictionary setValue:[duration isKindOfClass:[NSString class]] ? [NSNumber numberWithInt:[duration intValue]] : duration forKey:@"playbackDuration"];
            }
        }
        [mutableSongsToSerialize addObject:songDictionary];
    }

    successCallback(@[mutableSongsToSerialize]);
}

RCT_EXPORT_METHOD(playTracks:(NSArray *)tracks index:(int)index successCallback:(RCTResponseSenderBlock)successCallback) {
    NSLog(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    NSMutableArray *playlist = [[NSMutableArray alloc] initWithCapacity:0];
    
    for(int i = 0; i < [tracks count]; i++) {
        NSDictionary *query = [tracks objectAtIndex: i];
        
        MPMediaQuery *songsQuery = [MPMediaQuery songsQuery];
        
        
        if ([query objectForKey:@"title"] != nil) {
            NSString *searchTitle = [query objectForKey:@"title"];
            [songsQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:searchTitle forProperty:MPMediaItemPropertyTitle comparisonType:MPMediaPredicateComparisonContains]];
        }
        if ([query objectForKey:@"albumArtist"] != nil) {
            NSString *searchalbumArtist = [query objectForKey:@"albumArtist"];
            [songsQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:searchalbumArtist forProperty:MPMediaItemPropertyAlbumArtist comparisonType:MPMediaPredicateComparisonContains]];
        }
        
        for (MPMediaItem *song in songsQuery.items) {
            
            [playlist addObject: song];
        
        }
    }
    
    if (playlist.count == 0) {
        successCallback(@[@"Tracks have not been found"]);
        return;
    }
    
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
    MPMediaItemCollection *currentQueue = [[MPMediaItemCollection alloc] initWithItems:playlist];
    MPMediaItem *nowPlaying = [[currentQueue items] objectAtIndex:index];
    [musicPlayer setQueueWithItemCollection:currentQueue];
    [musicPlayer setNowPlayingItem:nowPlaying];
    
    [musicPlayer play];
    
    successCallback(@[[NSNull null]]);
}

RCT_EXPORT_METHOD(getCurrentPlayTime:(RCTResponseSenderBlock)callback) {
    NSLog(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));

    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer] ;
    double nowPlayingItemDuration = [[[musicPlayer nowPlayingItem] valueForProperty:MPMediaItemPropertyPlaybackDuration]doubleValue];
    double currentTime = (double) [musicPlayer currentPlaybackTime];
    
    NSNumber *number = [NSNumber numberWithInt:currentTime] ;
    callback(@[number]);
}

- (NSString *)imageToNSString:(UIImage *)image
{
    NSData *data = UIImagePNGRepresentation(image);

    return [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
}

@end
