//
//  IAPManager.h
//  In-purchasing-SDK
//
//  Created by huang le on 2019/11/14.
//  Copyright © 2019 Lete. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol IAPManagerObserver <NSObject>
@optional
/**
 示例数据:
 订阅型返回数据：
 {
     "expires_date" = "2019-11-19 07:16:09 Etc/GMT";
     "expires_date_ms" = 1574147769000;
     "expires_date_pst" = "2019-11-18 23:16:09 America/Los_Angeles";
     "is_in_intro_offer_period" = false;
     "is_trial_period" = false;
     "original_purchase_date" = "2019-11-18 09:58:49 Etc/GMT";
     "original_purchase_date_ms" = 1574071129000;
     "original_purchase_date_pst" = "2019-11-18 01:58:49 America/Los_Angeles";
     "original_transaction_id" = 1000000593757295;
     "product_id" = "com.fohgames.babydentist.subscribeMonth";
     "purchase_date" = "2019-11-19 07:11:09 Etc/GMT";
     "purchase_date_ms" = 1574147469000;
     "purchase_date_pst" = "2019-11-18 23:11:09 America/Los_Angeles";
     quantity = 1;
     "subscription_group_identifier" = 20574112;
     "transaction_id" = 1000000594171841;
     "web_order_line_item_id" = 1000000048349723;
 }
 
 消耗性返回数据：
 {
     "is_trial_period" = false;
     "original_purchase_date" = "2019-11-20 02:21:30 Etc/GMT";
     "original_purchase_date_ms" = 1574216490000;
     "original_purchase_date_pst" = "2019-11-19 18:21:30 America/Los_Angeles";
     "original_transaction_id" = 1000000594609766;
     "product_id" = "com.fohgame.babydentist.noad";
     "purchase_date" = "2019-11-20 02:21:30 Etc/GMT";
     "purchase_date_ms" = 1574216490000;
     "purchase_date_pst" = "2019-11-19 18:21:30 America/Los_Angeles";
     quantity = 1;
     "transaction_id" = 1000000594609766;
 }
 
 字段说明：
 expires_date 到期时间
 expires_date_ms 到期时间毫秒
 expires_date_pst 到期时间（太平洋的时间）
 is_trial_period 是否是在试用期
 original_purchase_date 最初的购买时间
 original_purchase_date_ms 最初的购买时间毫秒
 original_purchase_date_pst 最初的购买时间（太平洋的时间）
 product_id 产品id
 purchase_date 最新的购买时间
 purchase_date_ms 最新的购买时间毫秒
 purchase_date_pst 最新的购买时间（太平洋的时间）
 
 */
- (void)iapPaymentSuccess:(NSDictionary *)result;

/**
 示例数据：
 {
     message = "交易失败，用户取消交易或支付失败";
     status = 1005;
 }
 字段说明：
 status 错误码。
 message 错误提示，此字段有时会不存在，不应作为提示显示，只是辅助开发作用。
 错误情况：
 1001 用户不允许内购
 1002 没有该商品，请检查苹果后台设置是否正确
 1003 无法匹配商品，请检查与苹果后台设置是否一致
 1004 请求商品信息出错
 1005 交易失败，用户取消交易或支付失败
 1006 请求服务器验证失败
 1007 恢复购买失败，用户没有购买历史记录。
 1008 无效订单
 1009  当前登录账号有误
 21000 对App Store的请求不是使用HTTP POST请求方法发出的。
 21001 此状态代码不再由App Store发送。
 21002 receipt-data属性中的数据畸形或丢失。
 21003 这张收据不能被证实。
 21004 您提供的共享秘密与您的帐户文件上的共享秘密不匹配。
 21005 收据服务器当前不可用。
 21006 此收据有效，但订阅已过期。当此状态码返回到您的服务器时，接收数据也将被解码并作为响应的一部分返回。只返回iOS 6风格的自动更新订阅的交易收据。
 21007 这个收据来自测试环境，但是它被发送到生产环境进行验证。
 21008 这个收据来自生产环境，但是它被发送到测试环境进行验证。
 21009 内部数据访问错误。稍后再试。
 21010 用户帐户无法找到或已被删除。
 */
- (void)iapPaymentFail:(NSDictionary *)result;

@end


@interface IAPManager : NSObject

@property(nonatomic,assign)BOOL showLog;
//用户id
@property(nonatomic,copy)NSString *userId;

+ (instancetype)shareInstance;

/**
 observer 事务监听委托
 password App专用共享秘钥
 */
- (void)addTransactionObserver:(id <IAPManagerObserver>)observer password:(NSString *)password;

/**
 移除事务监听观察
 在applicationWillTerminate里实现
 */
- (void)removeTransactionObserver;

/**
 itmeId 在appstoreconnect配置的储值品项产品ID
 */
- (void)buyItem:(NSString *)itemId;

//恢复购买
- (void)restoreBuy;


@end

