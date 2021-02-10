//
//  Wrapper.h
//  SwiftNCNN
//
//  Created by Zilin Zhu on 2021/1/30.
//

#ifndef Wrapper_h
#define Wrapper_h

#import <Foundation/Foundation.h>

// MARK: Mat
@interface Mat : NSObject

- (instancetype)initFromPixels:(NSData*)data :(int)type :(int)w :(int)h;
- (instancetype)initFromPixelsResize:(NSData*)data :(int)type :(int)w :(int)h :(int)target_width :(int)target_height;
- (instancetype)initFromPathResize:(NSString*)path :(int)target_width :(int)target_height;
- (int)w;
- (int)h;
- (int)c;
- (NSData*)toData;
- (void)substractMeanNormalize:(NSArray<NSNumber*>*)mean :(NSArray<NSNumber*>*)std;
@end

// MARK: Net
@interface Net : NSObject

- (int)loadParam:(NSString*)paramPath;
- (int)loadParamBin:(NSString*)paramBinPath;
- (int)loadModel:(NSString*)modelPath;
- (void)clear;

- (int)registerCustomLayer:(NSString*)type;

- (NSDictionary<NSNumber *, Mat *> *)runWithIndex:(NSDictionary<NSNumber *, Mat *> *)inputs
                                            :(NSArray<NSNumber *> *)extracts;
- (NSDictionary<NSString *, Mat *> *)runWithName:(NSDictionary<NSString *, Mat *> *)inputs
                                            :(NSArray<NSString *> *)extracts;
@end

#endif /* Wrapper_h */
