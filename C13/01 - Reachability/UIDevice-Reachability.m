/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.0 Edition
 BSD License for anything not specifically marked as developed by a third party.
 Apple's code excluded.
 Use at your own risk
 */

#import <SystemConfiguration/SystemConfiguration.h>

#import <arpa/inet.h>
#import <netdb.h>
#import <net/if.h>
#import <ifaddrs.h>
#import <unistd.h>
#import <dlfcn.h>
#import <notify.h>

#import "UIDevice-Reachability.h"

@implementation UIDevice (Reachability)
SCNetworkConnectionFlags connectionFlags;
SCNetworkReachabilityRef reachability;

#pragma mark Class IP and Host Utilities 

// 跟IP相關的輔助方法，大都從Apple的範例程式碼修改而來，謝謝你，Apple。

+ (NSString *) stringFromAddress: (const struct sockaddr *) address
{
	if (address && address->sa_family == AF_INET) 
    {
		const struct sockaddr_in* sin = (struct sockaddr_in *) address;
		return [NSString stringWithFormat:@"%@:%d", [NSString stringWithUTF8String:inet_ntoa(sin->sin_addr)], ntohs(sin->sin_port)];
	}
	
	return nil;
}

+ (BOOL)addressFromString:(NSString *)IPAddress address:(struct sockaddr_in *)address
{
	if (!IPAddress || ![IPAddress length]) return NO;
	
	memset((char *) address, sizeof(struct sockaddr_in), 0);
	address->sin_family = AF_INET;
	address->sin_len = sizeof(struct sockaddr_in);
	
	int conversionResult = inet_aton([IPAddress UTF8String], &address->sin_addr);
	if (conversionResult == 0) 
    {
		NSAssert1(conversionResult != 1, @"Failed to convert the IP address string into a sockaddr_in: %@", IPAddress);
		return NO;
	}
	
	return YES;
}

+ (NSString *) addressFromData:(NSData *) addressData
{
    NSString *adr = nil;	
    if (addressData != nil)
    {
		struct sockaddr_in addrIn = *(struct sockaddr_in *)[addressData bytes];
		adr = [NSString stringWithFormat: @"%s", inet_ntoa(addrIn.sin_addr)];
    }	
    return adr;
}

+ (NSString *) portFromData:(NSData *) addressData
{
    NSString *port = nil;	
    if (addressData != nil)
    {
		struct sockaddr_in addrIn = *(struct sockaddr_in *)[addressData bytes];
		port = [NSString stringWithFormat: @"%hu", ntohs(addrIn.sin_port)];
    }	
    return port;
}

+ (NSData *) dataFromAddress: (struct sockaddr_in) address
{
	return [NSData dataWithBytes:&address length:sizeof(struct sockaddr_in)];
}

- (NSString *) hostname
{
	char baseHostName[256]; // 謝謝，Gunnar Larisch
	int success = gethostname(baseHostName, 255);
	if (success != 0) return nil;
	baseHostName[255] = '\0';
	
#if TARGET_IPHONE_SIMULATOR
 	return [NSString stringWithFormat:@"%s", baseHostName];
#else
	return [NSString stringWithFormat:@"%s.local", baseHostName];
#endif
}

- (NSString *) getIPAddressForHost: (NSString *) theHost
{
	struct hostent *host = gethostbyname([theHost UTF8String]);
    if (!host) {herror("resolv"); return NULL; }
	struct in_addr **list = (struct in_addr **)host->h_addr_list;
	NSString *addressString = [NSString stringWithCString:inet_ntoa(*list[0]) encoding:NSUTF8StringEncoding];
	return addressString;
}

- (NSString *) localIPAddress
{
	struct hostent *host = gethostbyname([[self hostname] UTF8String]);
    if (!host) {herror("resolv"); return nil;}
    struct in_addr **list = (struct in_addr **)host->h_addr_list;
	return [NSString stringWithCString:inet_ntoa(*list[0]) encoding:NSUTF8StringEncoding];
}

// Matt Brown取得WiFi IP的解決方案
// 感謝，讓我可用於這本著作，在此條款之下，
// http://mattbsoftware.blogspot.com/2009/04/how-to-get-ip-address-of-iphone-os-v221.html

// 更新iPhone熱點的程式碼，感謝Johannes Rudolph

- (NSString *) localWiFiIPAddress
{
	BOOL success;
	struct ifaddrs * addrs;
	const struct ifaddrs * cursor;
	
	success = getifaddrs(&addrs) == 0;
	if (success) {
		cursor = addrs;
		while (cursor != NULL) {
            
            // 第二項檢查，避免拿到loopback的位址
			if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0) 
			{
				NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];

                /*
                 // 除錯用
                 NSLog(@"Interface name: %@, inet: %d, loopback: %d, address: %@", 
                 name, 
                 cursor->ifa_addr->sa_family == AF_INET, 
                 (cursor->ifa_flags & IFF_LOOPBACK) == 0, 
                 [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)]);
                 */                

                // Wi-Fi配接器，或iPhone個人熱點橋接器
				if ([name isEqualToString:@"en0"] || 
                    [name isEqualToString:@"bridge0"])
					return [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
			}
			cursor = cursor->ifa_next;
		}
		freeifaddrs(addrs);
	}
	return nil;
}


- (NSArray *) localWiFiIPAddresses
{
	BOOL success;
	struct ifaddrs * addrs;
	const struct ifaddrs * cursor;
	
	NSMutableArray *array = [NSMutableArray array];
	
	success = getifaddrs(&addrs) == 0;
	if (success) {
		cursor = addrs;
		while (cursor != NULL) {
            
			// 第二項檢查，避免拿到loopback的位址
			if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0) 
			{
				NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                
                // Wi-Fi配接器，或iPhone個人熱點橋接器
				if ([name hasPrefix:@"en"] || [name hasPrefix:@"bridge"])
					[array addObject:[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)]];
			}
			cursor = cursor->ifa_next;
		}
		freeifaddrs(addrs);
	}
	
	if (array.count) return array;
	
	return nil;
}

- (NSString *) whatismyipdotcom
{
	NSError *error;
    NSURL *ipURL = [NSURL URLWithString:@"http://automation.whatismyip.com/n09230945.asp"];
    NSString *ip = [NSString stringWithContentsOfURL:ipURL encoding:NSUTF8StringEncoding error:&error];
	return ip ? ip : error.localizedFailureReason;
}

- (BOOL) hostAvailable: (NSString *) theHost
{
	
    NSString *addressString = [self getIPAddressForHost:theHost];
    if (!addressString)
    {
        NSLog(@"Error recovering IP address from host name\n");
        return NO;
    }
	
    struct sockaddr_in address;
    BOOL gotAddress = [UIDevice addressFromString:addressString address:&address];
	
    if (!gotAddress)
    {
		NSLog(@"Error recovering sockaddr address from %@", addressString);
        return NO;
    }
	
	SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&address);
    SCNetworkReachabilityFlags flags;
	
	BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
	
    if (!didRetrieveFlags)
    {
        NSLog(@"Error. Could not recover network reachability flags");
        return NO;
    }
	
    BOOL isReachable = (flags & kSCNetworkFlagsReachable) != 0;
    return isReachable ? YES : NO;;
}

#pragma mark Checking Connections
- (void) pingReachabilityInternal
{
	if (!reachability)
	{
		BOOL ignoresAdHocWiFi = NO;
		struct sockaddr_in ipAddress;
		bzero(&ipAddress, sizeof(ipAddress));
		ipAddress.sin_len = sizeof(ipAddress);
		ipAddress.sin_family = AF_INET;
		ipAddress.sin_addr.s_addr = htonl(ignoresAdHocWiFi ? INADDR_ANY : IN_LINKLOCALNETNUM);

		/* 若需要的話，也可建立零位址
		 struct sockaddr_in zeroAddress;
		 bzero(&zeroAddress, sizeof(zeroAddress));
		 zeroAddress.sin_len = sizeof(zeroAddress);
		 zeroAddress.sin_family = AF_INET; */
		
		reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (struct sockaddr *)&ipAddress);
		CFRetain(reachability);
	}
	
	// 取得可達性的旗標
	BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(reachability, &connectionFlags);
	if (!didRetrieveFlags) printf("Error. Could not recover network reachability flags\n");
}

- (BOOL) networkAvailable
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[self pingReachabilityInternal];
	BOOL isReachable = ((connectionFlags & kSCNetworkFlagsReachable) != 0);
    BOOL needsConnection = ((connectionFlags & kSCNetworkFlagsConnectionRequired) != 0);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    return (isReachable && !needsConnection) ? YES : NO;
}

// 感謝Johannes Rudolph
- (BOOL) activePersonalHotspot
{
    // 個人熱點固定為172.20.10
    NSString* localWifiAddress = [self localWiFiIPAddress];
    return (localWifiAddress != nil && [localWifiAddress hasPrefix:@"172.20.10"]);
}


- (BOOL) activeWWAN
{
	if (![self networkAvailable]) return NO;
	return ((connectionFlags & kSCNetworkReachabilityFlagsIsWWAN) != 0);
}

- (BOOL) activeWLAN
{
	return ([[UIDevice currentDevice] localWiFiIPAddress] != nil);
}

#pragma mark WiFi Check and Alert
- (void) privateShowAlert: (id) formatstring,...
{
	va_list arglist;
	if (!formatstring) return;
	va_start(arglist, formatstring);
	NSString *outstring = [[NSString alloc] initWithFormat:formatstring arguments:arglist];
	va_end(arglist);
	
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:outstring message:nil delegate:nil cancelButtonTitle:@"OK"otherButtonTitles:nil];
	[av show];
}

- (BOOL) performWiFiCheck
{
	if (![self networkAvailable] || ![self activeWLAN])
	{
		[self performSelector:@selector(privateShowAlert:) withObject:@"This application requires WiFi. Please enable WiFi in Settings and launch this application again." afterDelay:0.5f];
		return NO;
	}
	return YES;
}

#pragma mark Monitoring reachability
static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void* info)
{
    @autoreleasepool {
        id watcher = (__bridge id) info;
        if ([watcher respondsToSelector:@selector(reachabilityChanged)])
            [watcher performSelector:@selector(reachabilityChanged)];
    }
}

- (BOOL) scheduleReachabilityWatcher: (id <ReachabilityWatcher>) watcher
{
	[self pingReachabilityInternal];

	SCNetworkReachabilityContext context = {0, (__bridge void *)watcher, NULL, NULL, NULL};
	if(SCNetworkReachabilitySetCallback(reachability, ReachabilityCallback, &context)) 
	{
		if(!SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetCurrent(), kCFRunLoopCommonModes)) 
		{
			NSLog(@"Error: Could not schedule reachability");
			SCNetworkReachabilitySetCallback(reachability, NULL, NULL);
			return NO;
		}
	} 
	else 
	{
		NSLog(@"Error: Could not set reachability callback");
		return NO;
	}
	
	return YES;
}

- (void) unscheduleReachabilityWatcher
{
	SCNetworkReachabilitySetCallback(reachability, NULL, NULL);
	if (SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), kCFRunLoopCommonModes))
		NSLog(@"Unscheduled reachability");
	else
		NSLog(@"Error: Could not unschedule reachability");
	
	CFRelease(reachability);
	reachability = nil;
}
@end