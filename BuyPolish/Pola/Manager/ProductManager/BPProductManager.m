#import "Objection.h"
#import "BPProductManager.h"
#import "BPProduct.h"
#import "BPTaskRunner.h"
#import "BPAPIAccessor.h"
#import "BPTask.h"
#import "BPProduct+Utilities.h"
#import "BPAPIAccessor+Product.h"


@interface BPProductManager ()

@property(nonatomic, readonly) BPTaskRunner *taskRunner;
@property(nonatomic, readonly) BPAPIAccessor *apiAccessor;

@end


@implementation BPProductManager

objection_requires_sel(@selector(taskRunner), @selector(apiAccessor))

- (void)retrieveProductWithBarcode:(NSString *)barcode completion:(void (^)(BPProduct *, NSError *))completion completionQueue:(NSOperationQueue *)completionQueue {
    __block BPProduct *product;
    __block NSError *error;

    weakify()
    void (^block)() = ^{
        strongify()

        NSDictionary *productDictionary = [strongSelf.apiAccessor retrieveProductWithBarcode:barcode error:&error];

        if (error) {
            BPLog(@"Error while retrieve product: %@ %@", barcode, error.localizedDescription);
            return;
        }
        product = [[BPProduct alloc] init];
        [product parse:productDictionary];
    };
    void (^blockCompletion)() = ^{
        if (completion) {
            [completionQueue addOperationWithBlock:^{
                completion(product, error);
            }];
        }
    };
    BPTask *task = [BPTask taskWithlock:block completion:blockCompletion];
    [self.taskRunner runImmediateTask:task];
}

@end