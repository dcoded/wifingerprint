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

int main(int argc, char** argv)
{
    if (!db.connect()) {
        std::cout << "Could not connect to database, exiting...\n";
        exit(1);
    }

    std::string AREA_ID;
    std::string* AREA_PTR = &AREA_ID;
    std::vector<wifi_signal> cache;
    int sum_hash = 0;
    listener listener("en0");
    listener.event.poll = [&sum_hash, AREA_PTR, &cache] (std::vector<wifi_signal>& ap_array)
    {
        // do a quick sum of rssi to create a hash (prevent redundant data due to caching by NIC)
        int sum = std::accumulate(std::begin(ap_array), std::end(ap_array), 0,
        [](int init, wifi_signal ap) { return init - ap.rssi; });

        if (sum != sum_hash)
        {
            sum_hash = sum;
            const boost::uuids::uuid uuid = boost::uuids::random_generator()();
            std::cout << "sample=" << uuid << ", size=" << ap_array.size() << "\n";
            for (auto& ap : ap_array)
            {
                db.save_fingerprint(ap, *AREA_PTR, uuid);
            }

            cache.swap(ap_array);
            // for (wifi_signal ap : ap_array)
            // {
            //     std::cout << '[' << ap.bssid << ']' << " " << ap.rssi << " dB" << std::endl;
            //     // std::cout
            //     //     << '['  << i << '/' << ap.bssid << ']' << std::endl
            //     //     << '\t' << "ssid: " << ap.ssid         << std::endl
            //     //     << '\t' << "rssi: " << ap.rssi         << std::endl
            //     //     << std::endl;
            // }
        }
    };

    std::string cmd;
    bool run = true;
    while(run)
    {
        std::cout << "[" << AREA_ID << "]> ";
        std::cin >> cmd;
        if (cmd == "start") {
            if(AREA_ID == "") {
                std::cout << "area ID not yet defined.\n";
            } else {
                std::cout << "Starting Wi-Fi sniffer\n";
                listener.start();
            }
        }
        else if (cmd == "locate") {
            db.locate(cache);
        }
        else if (cmd == "stop") {
            std::cout << "Stopping Wi-Fi sniffer\n";
            listener.stop();
        }
        else if(cmd == "area") {
            std::cin >> AREA_ID;
        } else if(cmd == "data") {
            std::cout
                << "      BSSID          RSSI          SSID"       << std::endl
                << "-----------------   ------   ----------------" << std::endl;
            for(auto& ap : cache) {
                std::cout << ap.bssid << "   " << ap.rssi << " dB   " << ap.ssid << "\n";
            }
        }
    }
    return 0;
}