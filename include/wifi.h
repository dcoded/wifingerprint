#pragma once
#import <Foundation/Foundation.h>
#import <CoreWLAN/CoreWLAN.h>
#include <string>
#include <vector>

struct wifi_signal
{
    std::string ssid;
    std::string bssid;

    long rssi;
};

std::vector<wifi_signal> ScanAir(const std::string& interfaceName) {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    CWInterface* interface = [[CWWiFiClient sharedWiFiClient] interface];

    NSError* error   = nil;
    NSArray* scanned = nil;

    scanned = [[interface scanForNetworksWithSSID:nil error:&error] allObjects];
    
    if (error)
        NSLog(@"%@ (%ld)", [error localizedDescription], [error code]);

    std::vector<wifi_signal> result;
    for (CWNetwork* network : scanned) result.push_back({
        [[network ssid] UTF8String],  // Name of network (human readable)
        [[network bssid] UTF8String], // MAC Address of access point
        [network rssiValue]           // Strength of signal ( ex. -60 dB)
    });

    [pool drain];
    return result;
}