//
//  NcnnWrapper.h
//  SwiftNCNN
//
//  Created by Zilin Zhu on 2021/1/28.
//

#ifndef NcnnWrapper_h
#define NcnnWrapper_h

#import <Foundation/Foundation.h>

// MARK: Mat
@interface Mat : NSObject

- (instancetype)initFromPixels:(NSData*)data :(int)type :(int)w :(int)h;
- (NSData*)toData;
- (void)substractMeanNormalize:(NSArray<NSNumber*>*)mean :(NSArray<NSNumber*>*)std;
@end

// MARK: Net
@interface Net : NSObject
- (int)loadParam:(NSString*)paramPath;
- (int)loadParamBin:(NSString*)paramBinPath;
- (int)loadModel:(NSString*)modelPath;
- (void)clear;

- (NSDictionary<NSNumber *, Mat *> *)run:(NSDictionary<NSNumber *, Mat *> *)inputs
                                        :(NSArray<NSNumber *> *)extracts;
@end

#endif /* NcnnWrapper_h */
