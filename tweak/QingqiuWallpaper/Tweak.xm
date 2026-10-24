#import <UIKit/UIKit.h>
#import <notify.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <dlfcn.h>

static NSString *const QQRequestBoard = @"com.qingqiu.wallpaper.payload";
static NSString *const QQResultBoard = @"com.qingqiu.wallpaper.result";
static NSString *const QQRequestNotification = @"com.qingqiu.wallpaper.set-request";
static NSString *const QQResultNotification = @"com.qingqiu.wallpaper.set-result";

static void QQTrace(NSString *event) {
    NSString *line = [NSString stringWithFormat:@"%@ %@\n", [[NSDate date] description], event ?: @"unknown"];
    NSString *path = @"/var/mobile/Library/Preferences/com.qingqiu.wallpaper.trace";
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!handle) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        handle = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    [handle seekToEndOfFile];
    [handle writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    [handle closeFile];
}

static void QQWriteResult(BOOL ok, NSString *message) {
    QQTrace([NSString stringWithFormat:@"write-result ok=%@ message=%@", ok ? @"YES" : @"NO", message ?: @""]);
    NSDictionary *result = @{@"ok": @(ok), @"message": message ?: @"unknown", @"timestamp": @([[NSDate date] timeIntervalSince1970])};
    NSData *data = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        UIPasteboard *board = [UIPasteboard pasteboardWithName:QQResultBoard create:YES];
        [board setData:data forPasteboardType:@"public.json"];
        [[UIPasteboard generalPasteboard] setData:data forPasteboardType:@"public.json"];
        notify_post(QQResultNotification.UTF8String);
    });
}

static UIImage *QQImageForScreen(UIImage *image) {
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize target = CGSizeMake(bounds.size.width * scale, bounds.size.height * scale);
    if (image.size.width <= 0 || image.size.height <= 0 || target.width <= 0 || target.height <= 0) return nil;
    UIGraphicsBeginImageContextWithOptions(target, YES, 1.0);
    CGFloat factor = MAX(target.width / image.size.width, target.height / image.size.height);
    CGSize drawn = CGSizeMake(image.size.width * factor, image.size.height * factor);
    CGRect rect = CGRectMake((target.width - drawn.width) / 2.0, (target.height - drawn.height) / 2.0, drawn.width, drawn.height);
    [image drawInRect:rect];
    UIImage *output = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return output;
}

typedef void (*QQWallpaperImageLocationsFunction)(id image, NSInteger locations);

static BOOL QQCallWallpaperService(UIImage *image, NSString **failure) {
    // iOS 16 moved wallpaper writes behind SpringBoardServices/SpringBoardUI
    // and no longer exposes the old SBWallpaperController setters.
    NSArray<NSString *> *frameworks = @[
        @"/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices",
        @"/System/Library/PrivateFrameworks/SpringBoardUI.framework/SpringBoardUI"
    ];
    NSArray<NSString *> *symbols = @[
        @"SBSetWallpaperImageForLocations",
        @"SBSUIWallpaperSetImageAsWallpaperForLocations"
    ];
    for (NSString *framework in frameworks) {
        void *handle = dlopen(framework.UTF8String, RTLD_LAZY | RTLD_LOCAL);
        if (!handle) {
            QQTrace([NSString stringWithFormat:@"wallpaper-dlopen-failed %@", framework]);
            continue;
        }
        for (NSString *symbol in symbols) {
            void *address = dlsym(handle, symbol.UTF8String);
            QQTrace([NSString stringWithFormat:@"wallpaper-symbol %@ %@", symbol, address ? @"found" : @"missing"]);
            if (!address) continue;
            // Location bits are Lock Screen = 1, Home Screen = 2.
            ((QQWallpaperImageLocationsFunction)address)(image, 3);
            QQTrace([NSString stringWithFormat:@"wallpaper-symbol-called %@", symbol]);
            dlclose(handle);
            return YES;
        }
        dlclose(handle);
    }
    *failure = @"No supported wallpaper service symbol found on this iOS build";
    return NO;
}

static BOOL QQSetVariant(UIImage *image, NSInteger variant, NSString **failure) {
    Class controllerClass = objc_getClass("SBWallpaperController");
    if (!controllerClass) controllerClass = objc_getClass("SBFWallpaperController");
    if (!controllerClass) { *failure = @"iOS wallpaper controller class not found"; return NO; }

    id controller = nil;
    for (NSString *name in @[@"sharedInstance", @"sharedController", @"defaultController"]) {
        SEL selector = NSSelectorFromString(name);
        if ([controllerClass respondsToSelector:selector]) {
            controller = ((id (*)(id, SEL))objc_msgSend)(controllerClass, selector);
            if (controller) break;
        }
    }
    if (!controller) { *failure = @"iOS wallpaper controller instance unavailable"; return NO; }

    for (NSString *name in @[@"setWallpaperImage:forVariant:", @"setWallpaperImage:forVariant:options:"]) {
        SEL selector = NSSelectorFromString(name);
        if (![controller respondsToSelector:selector]) continue;
        NSMethodSignature *signature = [controller methodSignatureForSelector:selector];
        const char *variantType = signature.numberOfArguments > 3 ? [signature getArgumentTypeAtIndex:3] : "";
        BOOL integerVariant = variantType[0] == 'i' || variantType[0] == 'I' || variantType[0] == 'q' || variantType[0] == 'Q';
        if (signature.numberOfArguments == 4 && integerVariant) {
            ((void (*)(id, SEL, id, NSInteger))objc_msgSend)(controller, selector, image, variant);
            NSLog(@"[QingqiuWallpaper] invoked %@ with variant %ld", name, (long)variant);
            return YES;
        }
        const char *optionsType = signature.numberOfArguments > 4 ? [signature getArgumentTypeAtIndex:4] : "";
        if (signature.numberOfArguments == 5 && integerVariant && optionsType[0] == '@') {
            ((void (*)(id, SEL, id, NSInteger, id))objc_msgSend)(controller, selector, image, variant, @{});
            NSLog(@"[QingqiuWallpaper] invoked %@ with variant %ld", name, (long)variant);
            return YES;
        }
    }
    NSLog(@"[QingqiuWallpaper] no compatible wallpaper setter on %@", NSStringFromClass(controllerClass));
    *failure = @"No supported wallpaper setter found on this iOS build";
    return NO;
}

static BOOL QQSetWallpaper(UIImage *image, NSString **failure) {
    if (QQCallWallpaperService(image, failure)) return YES;
    return QQSetVariant(image, 0, failure) && QQSetVariant(image, 1, failure);
}

static void QQHandleRequest(void) {
    QQTrace(@"request-received");
    QQTrace(@"pasteboard-open-start");
    UIPasteboard *board = [UIPasteboard pasteboardWithName:QQRequestBoard create:NO];
    QQTrace(@"pasteboard-open-done");
    QQTrace(@"named-read-start");
    NSData *data = [board dataForPasteboardType:@"public.data"];
    QQTrace([NSString stringWithFormat:@"named-read-done bytes=%lu", (unsigned long)data.length]);
    if (!data.length) {
        QQTrace(@"general-read-start");
        data = [[UIPasteboard generalPasteboard] dataForPasteboardType:@"public.data"];
        QQTrace([NSString stringWithFormat:@"general-read-done bytes=%lu", (unsigned long)data.length]);
    }
    QQTrace([NSString stringWithFormat:@"request-data-bytes=%lu", (unsigned long)data.length]);
    UIImage *source = data.length ? [UIImage imageWithData:data] : nil;
    if (!source) { QQWriteResult(NO, @"Wallpaper payload missing or invalid"); return; }

    UIImage *image = QQImageForScreen(source);
    if (!image) { QQWriteResult(NO, @"Could not prepare wallpaper image"); return; }

    dispatch_async(dispatch_get_main_queue(), ^{
        QQTrace(@"wallpaper-set-start");
        NSString *failure = nil;
        if (!QQSetWallpaper(image, &failure)) { QQWriteResult(NO, failure); return; }
        QQTrace(@"wallpaper-set-done");
        QQWriteResult(YES, @"Home and Lock screens updated");
    });
}

%ctor {
    if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) return;
    QQTrace(@"ctor-loaded");
    int token = 0;
    notify_register_dispatch(QQRequestNotification.UTF8String, &token, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^(int value) {
        QQTrace(@"request-callback-background");
        QQHandleRequest();
    });
}


