#import "whisper-encoder.h"
#import <CoreML/CoreML.h>
#import <Foundation/Foundation.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with automatic reference counting enabled (-fobjc-arc)
#endif

struct whisper_coreml_context {
    MLModel * model;
    NSString * inputName;
    NSString * outputName;
};

extern "C" {

struct whisper_coreml_context * whisper_coreml_init(const char * path_model) {
    NSString * path = [NSString stringWithUTF8String:path_model];
    NSURL * modelURL = [NSURL fileURLWithPath:path];
    
    NSError * error = nil;
    MLModelConfiguration * config = [[MLModelConfiguration alloc] init];
    config.computeUnits = MLComputeUnitsAll; // Use Neural Engine (ANE) if available

    // Load model dynamically without generated class
    MLModel * model = [MLModel modelWithContentsOfURL:modelURL configuration:config error:&error];
    if (error || model == nil) {
        NSLog(@"[whisper-coreml] Error loading model from %s: %@", path_model, error);
        return nullptr;
    }

    whisper_coreml_context * ctx = new whisper_coreml_context;
    ctx->model = model;
    
    // Default names for whisper.cpp CoreML models
    ctx->inputName = @"logmel_data"; 
    ctx->outputName = @"output_features";
    
    return ctx;
}

void whisper_coreml_free(struct whisper_coreml_context * ctx) {
    if (ctx) {
        delete ctx;
    }
}

void whisper_coreml_encode(
        const struct whisper_coreml_context * ctx,
                             int64_t   n_ctx,
                             int64_t   n_mel,
                               float * mel,
                               float * out) {
    
    NSError * error = nil;
    
    // 1. Prepare Input MLMultiArray (Support both 80 and 128 mel bands)
    // Shape: [1, n_mel, n_ctx] (e.g., [1, 128, 3000] for Large-v3-Turbo)
    NSArray<NSNumber *> * shape = @[@1, @(n_mel), @(n_ctx)];
    NSArray<NSNumber *> * strides = @[@(n_mel * n_ctx), @(n_ctx), @1];
    
    MLMultiArray * inputData = [[MLMultiArray alloc] initWithDataPointer:(void *)mel
                                                                  shape:shape
                                                               dataType:MLMultiArrayDataTypeFloat32
                                                                strides:strides
                                                            deallocator:nil
                                                                  error:&error];
    if (error) {
        NSLog(@"[whisper-coreml] Input multiarray error: %@", error);
        return;
    }
    
    // 2. Create Feature Provider
    NSDictionary * inputDict = @{ ctx->inputName : [MLFeatureValue featureValueWithMultiArray:inputData] };
    MLDictionaryFeatureProvider * inputFeatures = [[MLDictionaryFeatureProvider alloc] initWithDictionary:inputDict error:&error];

    // 3. Run Prediction
    MLPredictionOptions * options = [[MLPredictionOptions alloc] init];
    id<MLFeatureProvider> outputFeatures = [ctx->model predictionFromFeatures:inputFeatures options:options error:&error];

    if (error || outputFeatures == nil) {
        NSLog(@"[whisper-coreml] Prediction error: %@", error);
        return;
    }

    // 4. Extract Output and copy to raw buffer
    MLMultiArray * outputArray = [[outputFeatures featureValueForName:ctx->outputName] multiArrayValue];
    if (outputArray) {
        memcpy(out, outputArray.dataPointer, outputArray.count * sizeof(float));
    }
}

} // extern "C"
