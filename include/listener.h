/*
SELECT area, ssid, MAX(rssi)
FROM fingerprint
GROUP BY area,ssid
ORDER BY area,rssi DESC


SELECT area, SUM(hits) as sample_size, MIN(rssi), MAX(rssi), AVG(rssi) AS unweighted, SUM(rssi * hits) / SUM(hits) AS weighted
FROM fingerprint
GROUP BY area
ORDER BY weighted DESC, area
*/

#pragma once
#include <wifi.h>
#include <thread>
#include <vector>

class listener {
private:
    const std::string interface_;
    bool executing_ = false;

    void poll();

public:
    struct event_namespace {
        std::function<void(std::vector<wifi_signal>&)>
        poll = [] (std::vector<wifi_signal>&) {};
    };
    event_namespace event;

    std::thread thread_;

    listener(const std::string& interface);
    ~listener();

    void start();
    void stop();
    void join();
};


void listener::poll()
{
    while(executing_)
    {
        std::vector<wifi_signal> access_points = ScanAir(interface_);
        // sort wifi_signals from strongest to weakest signal with RSSI value
        std::sort(std::begin(access_points), std::end(access_points),
        [] (const wifi_signal& lhs, const wifi_signal& rhs) {
            return lhs.rssi > rhs.rssi;
        });

        event.poll(access_points);
        sleep(1);
    }
}


listener::listener(const std::string& interface)
    : interface_(interface)
    , executing_(false) {}

listener::~listener() { stop(); }

void listener::start () {
    if (executing_ == false) {
        thread_ = std::thread(&listener::poll, this);
        executing_ = true;
    }
}

void listener::stop () {
    if (executing_) {
        executing_ = false;
        thread_.join();
    }
}

void listener::join() {
    if(executing_) {
        thread_.join();
    }
}