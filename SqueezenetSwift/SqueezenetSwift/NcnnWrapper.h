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
struct _Mat;
@interface NcnnMat : NSObject
{
    @public struct _Mat *_mat;
}

- (instancetype)initFromPixels:(NSData*)data :(int)type :(int)w :(int)h;
- (NSData*)toData;
- (void)substractMeanNormalize:(NSArray<NSNumber*>*)mean :(NSArray<NSNumber*>*)std;
@end

// MARK: Net
struct _Net;
@interface NcnnNet : NSObject
{
    @public struct _Net *_net;
}
- (int)loadParam:(NSString*)paramPath;
- (int)loadParamBin:(NSString*)paramBinPath;
- (int)loadModel:(NSString*)modelPath;
- (void)clear;

- (NSDictionary<NSNumber *, NcnnMat *> *)run:(NSDictionary<NSNumber *, NcnnMat *> *)inputs
                                            :(NSArray<NSNumber *> *)extracts;
@end

#endif /* NcnnWrapper_h */
