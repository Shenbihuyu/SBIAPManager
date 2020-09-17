//
//  IAPManager.m
//  In-purchasing-SDK
//
//  Created by huang le on 2019/11/14.
//  Copyright © 2019 Lete. All rights reserved.
//

#import "IAPManager.h"
#import <StoreKit/StoreKit.h>

#define IAPLog(...)\
if(self.showLog)\
{\
printf("IAPManager %s\n",[[NSString stringWithFormat:__VA_ARGS__]UTF8String]);\
}\

@interface IAPManager()<SKPaymentTransactionObserver,SKProductsRequestDelegate>

@property(nonatomic,copy)NSString *itemId;
@property(nonatomic,copy)NSString *password;
@property(nonatomic,assign)BOOL isRestore;
@property(NS_NONATOMIC_IOSONLY, weak, nullable)id<IAPManagerObserver> delegate;

@end

@implementation IAPManager

 
+ (instancetype)shareInstance{
    static IAPManager *single;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        single = [[super allocWithZone:NULL] init];
        single.showLog = NO;
    });
    
    return single;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [IAPManager shareInstance] ;
}
 
- (id)copyWithZone:(struct _NSZone *)zone{
    return [IAPManager shareInstance] ;
}
 
- (void)addTransactionObserver:(id <IAPManagerObserver>)observer password:(NSString *)password{
    self.password = password;
    self.delegate = observer;
    self.isRestore = NO;
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}


- (void)removeTransactionObserver{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}


//购买产品
- (void)buyItem:(NSString *)itemId{
    self.isRestore = NO;
    //是否允许内购
    if ([SKPaymentQueue canMakePayments]) {
        IAPLog(@"用户允许内购");
        self.itemId = itemId;
        //itemId 就是你添加内购条目设置的产品ID
        NSArray *product = [[NSArray alloc] initWithObjects:itemId,nil];
        NSSet *nsset = [NSSet setWithArray:product];

        //初始化请求
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
        request.delegate = self;

        //开始请求
        [request start];

    }else{
        IAPLog(@"用户不允许内购");
        [self fail:[NSDictionary dictionaryWithObjectsAndKeys:@1001,@"status",@"用户不允许内购",@"message", nil]];
    }
}

//恢复购买
- (void)restoreBuy{
    self.isRestore = YES;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];//发起请求
}

#pragma mark - SKProductsRequestDelegate
//接收到产品的返回信息，然后用返回的商品信息进行发起购买请求
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response NS_AVAILABLE_IOS(3_0){
    NSArray *product = response.products;

    //如果服务器没有产品
    if([product count] == 0){
        IAPLog(@"没有该商品，请检查苹果后台设置是否正确");
        [self fail:[NSDictionary dictionaryWithObjectsAndKeys:@1002,@"status",@"没有该商品，请检查苹果后台设置是否正确",@"message", nil]];
        return;
    }

    SKProduct *requestProduct = nil;
    for (SKProduct *pro in product) {

        IAPLog(@"description %@", [pro description]);
        IAPLog(@"localizedTitle %@", [pro localizedTitle]);
        IAPLog(@"localizedDescription %@", [pro localizedDescription]);
        IAPLog(@"price %@", [pro price]);
        IAPLog(@"productIdentifier %@", [pro productIdentifier]);

        //如果后台消费条目的ID与我这里需要请求的一样（用于确保订单的正确性）
        if([pro.productIdentifier isEqualToString:self.itemId]){
            requestProduct = pro;
        }
    }

    if(requestProduct == nil){
        IAPLog(@"无法匹配商品，请检查与苹果后台设置是否一致");
        [self fail:[NSDictionary dictionaryWithObjectsAndKeys:@1003,@"status",@"无法匹配商品，请检查与苹果后台设置是否一致",@"message", nil]];
    }else{
        //发送购买请求
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:requestProduct];
        //可以是userId，也可以是订单id，跟你自己需要而定
        if(self.userId){
            payment.applicationUsername = self.userId;
        }
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

#pragma mark - SKRequestDelegate
//请求失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    IAPLog(@"请求商品信息出错：error:%@", error);
    [self fail:[NSDictionary dictionaryWithObjectsAndKeys:@1004,@"status",@"请求商品信息出错",@"message", nil]];
}

//请求结束
- (void)requestDidFinish:(SKRequest *)request{
    IAPLog(@"请求结束");
}

#pragma mark - SKPaymentTransactionObserver
//监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    IAPLog(@"transactions %@",transactions);
    if(self.isRestore){
        for(SKPaymentTransaction *tran in transactions){
            if(tran != transactions.lastObject){
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
            }
        }
        SKPaymentTransaction *tran = transactions.lastObject;
        IAPLog(@"tran.transactionIdentifier %@",tran.transactionIdentifier);
        IAPLog(@"tran.payment.productIdentifier %@",tran.payment.productIdentifier);
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchased:
                IAPLog(@"交易完成");
                [self completeTransaction:tran inSandbox:NO];
                
                break;
            case SKPaymentTransactionStatePurchasing:
                IAPLog(@"商品添加进列表");
                
                break;
            case SKPaymentTransactionStateRestored:
                IAPLog(@"已经购买过商品");
                [self restoreTransaction:tran];
                
                break;
            case SKPaymentTransactionStateFailed:
                IAPLog(@"交易失败");
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                if([tran.payment.productIdentifier isEqualToString:self.itemId]){
                    [self fail:[NSDictionary dictionaryWithObjectsAndKeys:@1005,@"status",@"交易失败，用户取消交易或支付失败",@"message", nil]];
                }
                
                break;
            default:
                break;
        }
        self.isRestore = NO;
    }else{
        for(SKPaymentTransaction *tran in transactions){
            IAPLog(@"tran.transactionIdentifier %@",tran.transactionIdentifier);
            IAPLog(@"tran.payment.productIdentifier %@",tran.payment.productIdentifier);
            switch (tran.transactionState) {
                case SKPaymentTransactionStatePurchased:
                    IAPLog(@"交易完成");
                    [self completeTransaction:tran inSandbox:NO];

                    break;
                case SKPaymentTransactionStatePurchasing:
                    IAPLog(@"商品添加进列表");

                    break;
                case SKPaymentTransactionStateRestored:
                    IAPLog(@"已经购买过商品");
                    [self restoreTransaction:tran];

                    break;
                case SKPaymentTransactionStateFailed:
                    IAPLog(@"交易失败");
                    [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                    if([tran.payment.productIdentifier isEqualToString:self.itemId]){
                        [self fail:[NSDictionary dictionaryWithObjectsAndKeys:@1005,@"status",@"交易失败，用户取消交易或支付失败",@"message", nil]];
                    }

                    break;
                default:
                    break;
            }
        }
    }
}

//恢复失败
- (void)paymentQueue:(SKPaymentQueue *) paymentQueue restoreCompletedTransactionsFailedWithError:(NSError *)error{
    IAPLog(@"-------restoreCompletedTransactionsFailedWithError----%@",error);
    self.isRestore = NO;
    [self fail:[NSDictionary dictionaryWithObjectsAndKeys:@1007,@"status",@"恢复购买失败",@"message", nil]];
}

//恢复完成
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue API_AVAILABLE(ios(3.0), macos(10.7)){
    IAPLog(@"用户购买历史记录中的所有事务都成功添加回队列完成");
    if([SKPaymentQueue defaultQueue].transactions.count >0){
        IAPLog(@"-------paymentQueueRestoreCompletedTransactionsFinished----%@",[SKPaymentQueue defaultQueue].transactions);
    }else{
        IAPLog(@"恢复购买失败，用户没有购买历史记录");
        self.isRestore = NO;
        [self fail:[NSDictionary dictionaryWithObjectsAndKeys:@1007,@"status",@"恢复购买失败，用户没有购买历史记录",@"message", nil]];
    }
}

#pragma mark -- 购买成功处理
//交易结束,当交易结束后还要去appstore上验证支付信息是否都正确,只有所有都正确后,我们就可以给用户发放我们的虚拟物品了。
- (void)completeTransaction:(SKPaymentTransaction *)transaction inSandbox:(BOOL)sandbox{
    // 验证凭据，获取到苹果返回的交易凭据
    // appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    // 从沙盒中获取到购买凭据
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    NSString *productId = transaction.payment.productIdentifier;
    NSString *applicationUsername = transaction.payment.applicationUsername;
    if(applicationUsername && self.userId){
        if(![self.userId isEqualToString:applicationUsername]){
            //不是购买时的登录账号，防止登录其他账号使用恢复购买功能给其他账号开通会员。
            [self fail:[NSDictionary dictionaryWithObjectsAndKeys:@1009,@"status",@"当前登录账号有误",@"message", nil]];
            return;
        }
    }
    //发送POST请求，对购买凭据进行验证
    NSString *AppStore_URL;
    if (sandbox) {
        //测试验证地址
        AppStore_URL = @"https://sandbox.itunes.apple.com/verifyReceipt";
    }else{
        //正式验证地址
        AppStore_URL = @"https://buy.itunes.apple.com/verifyReceipt";
    }
    
    NSURL *url = [NSURL URLWithString:AppStore_URL];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0f];
    urlRequest.HTTPMethod = @"POST";
    NSString *encodeStr = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *payload;
    if(self.password != nil && self.password.length > 0){
        payload = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\", \"exclude-old-transactions\" : \"true\", \"password\" : \"%@\"}", encodeStr, self.password];
    }else{
        payload = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\", \"exclude-old-transactions\" : \"true\"}", encodeStr];
    }
    
    IAPLog(@"payment.productIdentifier++++%@",productId);
//    IAPLog(@"receipt-data %@",payload);
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    urlRequest.HTTPBody = payloadData;
    
    NSURLSession *sharedSession = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *dataTask = [sharedSession dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data && (error == nil)) {
            // 网络访问成功
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            IAPLog(@"请求成功后的数据:%@",dic);
            //这个收据来自测试环境，但是它被发送到生产环境进行验证。
            if([[dic objectForKey:@"status"] intValue] == 21007){
                [self completeTransaction:transaction inSandbox:YES];
                return;
            }else if ([[dic objectForKey:@"status"] intValue] == 0){
                if(dic[@"latest_receipt_info"] != nil){
                    for (NSDictionary *info in dic[@"latest_receipt_info"]) {
                        [self success:info];
                    }
                }else if (dic[@"receipt"][@"in_app"] != nil){
                    NSArray *inapps = dic[@"receipt"][@"in_app"];
                    [self success:[inapps lastObject]];
                }
                else{
                    [self fail:[NSDictionary dictionaryWithObjectsAndKeys:@1008,@"status",@"无效订单",@"message", nil]];
                }
                //关闭事务
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
            }else{
                if([productId isEqualToString:self.itemId]){
                    [self fail:[NSDictionary dictionaryWithObjectsAndKeys:dic[@"status"],@"status",@"服务器验证失败",@"message", nil]];
                }
                //关闭事务
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
            }
        } else {
            // 网络访问失败
            IAPLog(@"服务器验证失败");
            if([productId isEqualToString:self.itemId]){
                [self fail:[NSDictionary dictionaryWithObjectsAndKeys:@1006,@"status",@"请求服务器验证失败",@"message", nil]];
            }
            return;
        }
    }];
    
    [dataTask resume];
    
}


#pragma mark -- 恢复交易处理
- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    IAPLog(@" 交易恢复处理ing");
    [self completeTransaction:transaction inSandbox:NO];
}

#pragma mark --成功失败处理
- (void)success:(NSDictionary *)dic{
    if([self.delegate respondsToSelector:@selector(iapPaymentSuccess:)]){
        [self.delegate iapPaymentSuccess:dic];
    }
}

- (void)fail:(NSDictionary *)dic{
    if([self.delegate respondsToSelector:@selector(iapPaymentFail:)]){
        [self.delegate iapPaymentFail:dic];
    }
}

@end
