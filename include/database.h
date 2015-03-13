#ifndef INCLUDE_DATABASE_H
#define INCLUDE_DATABASE_H

#include <config.h>
#include <wifi.h>

#include <sstream>

#include <mysql_connection.h>
#include <cppconn/driver.h>
#include <cppconn/exception.h>
#include <cppconn/resultset.h>
#include <cppconn/statement.h>
#include <cppconn/prepared_statement.h>

#include <boost/lexical_cast.hpp>
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_generators.hpp>
#include <boost/uuid/uuid_io.hpp>         // streaming operators etc.

class database {
private:
    config settings;

    /* Create a connection */
    sql::Driver* driver_;

    /* Connect to the MySQL test database */
    std::unique_ptr<sql::Connection> dbconn_;

    std::string MYSQL_HOST;
    std::string MYSQL_USER;
    std::string MYSQL_PASS;
    std::string MYSQL_DATA;
public:
    bool connect();

    void save_fingerprint(const wifi_signal& ap, const std::string& area,
                          const boost::uuids::uuid& uuid);

    std::string locate(const std::vector<wifi_signal>& ap_array);
};


bool database::connect()
{
    MYSQL_HOST = settings["MySQL.Hostname"];
    MYSQL_USER = settings["MySQL.Username"];
    MYSQL_PASS = settings["MySQL.Password"];
    MYSQL_DATA = settings["MySQL.Database"];

    std::cout
        << "Connecting to " << MYSQL_USER << ":" << MYSQL_PASS
        << "@" << MYSQL_HOST << "/" << MYSQL_DATA << "\n";

    try
    {
        driver_ = get_driver_instance();

        auto conn = driver_->connect(MYSQL_HOST,MYSQL_USER, MYSQL_PASS);
        /* Connect to the MySQL test database */
        dbconn_ = std::unique_ptr<sql::Connection>(conn);
        dbconn_->setSchema(MYSQL_DATA);
    }
    catch(...)
    {
        return false;
    }

    return true;
}

void database::save_fingerprint(const wifi_signal& ap, const std::string& area,
                                const boost::uuids::uuid& uuid)
try
{
    std::ostringstream oss;
    oss <<
        "INSERT INTO RawData (`SampleId`, `BSSID`, `RSSI`, `Landmark`, `SSID`)"
        "VALUES (" <<
            "'" << boost::lexical_cast<std::string>(uuid) << "'" << ","
            "'" << ap.bssid                               << "'" << ","
                << ap.rssi                                       << ","
            "'" << area                                   << "'" << ","
            "'" << ap.ssid                                << "'"
        << ");";

    auto dbstmt = std::unique_ptr<sql::Statement>(dbconn_->createStatement());
    dbstmt->execute(oss.str());
}
catch (sql::SQLException &e)
{
    std::cout << "# ERR: SQLException in " << __FILE__
              << "(" << __FUNCTION__ << ") on line »" << __LINE__ <<
    std::endl << "# ERR: " << e.what()
              << " (MySQL error code: " << e.getErrorCode()
              << ", SQLState: " << e.getSQLState() << " )" <<
    std::endl;
}



std::string database::locate(const std::vector<wifi_signal>& ap_array)
try
{
    for(auto& ap : ap_array)
    {
        std::unique_ptr<sql::Statement> dbstmt;
        std::unique_ptr<sql::ResultSet> result;
        std::ostringstream oss;
        oss << "CALL RankedNN(10, '" << ap.bssid << "', " << ap.rssi << ");";

        dbstmt = std::unique_ptr<sql::Statement>(dbconn_->createStatement());
        result = std::unique_ptr<sql::ResultSet>(dbstmt->executeQuery(oss.str()));

        std::cout << "      BSSID      \t RSSI \tL\tF\tAvgD" <<
        std::endl << "-----------------\t------\t-\t-\t----" <<
        std::endl;

        while(result->next())
        {
            auto LandmarkId  = result->getString("LandmarkId");
            auto Frequency   = result->getInt   ("Frequency");
            auto AvgDistance = result->getDouble("AvgDistance");

            std::cout << ap.bssid    << "\t"
                      << ap.rssi     << " dB\t"
                      << LandmarkId  << "\t"
                      << Frequency   << "\t"
                      << AvgDistance << "\n";

        }
    }
}
catch (sql::SQLException &e)
{
    std::cout << "# ERR: SQLException in " << __FILE__
              << "(" << __FUNCTION__ << ") on line »" << __LINE__ <<
    std::endl << "# ERR: " << e.what()
              << " (MySQL error code: " << e.getErrorCode()
              << ", SQLState: " << e.getSQLState() << " )" <<
    std::endl;
}


#endif