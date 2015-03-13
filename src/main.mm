#include <listener.h>
#include <numeric>
#include <iostream>
#include <algorithm>
#include <memory>
#include <string>
#include <thread>
#include <future>
#include <cctype>

#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_generators.hpp>
#include <boost/uuid/uuid_io.hpp>         // streaming operators etc.

#include <database.h>

database db;

void nic_poll_callback(const char* landmark, std::vector<wifi_signal>& ap_array);

int main(int argc, char** argv)
{
    if (argc < 2) {
        std::cout << "Usage: " << argv[0] << " <landmark>" << std::endl;
        exit(1);
    }

    if (!db.connect()) {
        std::cout << "Could not connect to database, exiting...\n";
        exit(2);
    }
    
    listener listener("en0");
    listener.event.poll = std::bind(nic_poll_callback, argv[1],
                                    std::placeholders::_1);

    listener.start();
    listener.join();
    return 0;
}

void nic_poll_callback(const char* landmark, std::vector<wifi_signal>& ap_array)
{
    static int sum_hash = 0;
    // do a quick sum of rssi to create a hash
    // (prevents redundant data due to caching by NIC)
    int sum = std::accumulate(std::begin(ap_array), std::end(ap_array), 0,
    [](int init, wifi_signal ap) { return init - ap.rssi; });

    if (sum != sum_hash) {
        std::cout << "\r";
        sum_hash = sum;
        const boost::uuids::uuid uuid = boost::uuids::random_generator()();
        std::cout
            << std::endl
            << "---------------------------------------------" << std::endl
            << "UUID: " << uuid                                << std::endl
            << "Size: " << ap_array.size()                     << std::endl
                                                               << std::endl
            << "      BSSID          RSSI          SSID"       << std::endl
            << "-----------------   ------   ----------------" << std::endl;
        for (auto& ap : ap_array)
        {
            db.save_fingerprint(ap, landmark, uuid);
            std::cout
                << ap.bssid << "   "
                << ap.rssi << " dB   "
                << ap.ssid << std::endl;
        }
    }
}