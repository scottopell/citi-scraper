require 'bundler/setup'
Bundler.require(:default, :test, :development)

db = SQLite3::Database.new('data.db')

# http://www.sqlite.org/faq.html#q19
db.default_synchronous = 'OFF'

# primary key is both id and total_docks because if a station adds or removes
# capacity at some point, then we want to record this event as well as the time
# at which it takes place. That way we can compare the time in available_bikes
# to all matches of station_id and find best match.
# Future improvement:
#   figure out a good way to record the station primary key in the
#   available_bikes table so that you don't have to compare the dates.
#   the current way seems hacky (and slow)
db.execute_batch <<-SQL
  CREATE TABLE if not exists stations (
           id            INTEGER        NOT NULL,
           status        VARCHAR(30),
           total_docks   INTEGER,
           latitude      FLOAT,
           longitude     FLOAT,
           label         VARCHAR(30)    NOT NULL,
           time          DATETIME,
           PRIMARY KEY (id, total_docks)
  );
  CREATE TABLE if not exists available_bikes (
           station_id   INTEGER   NOT NULL,
           time         DATETIME  NOT NULL,
           count        INTEGER   NOT NULL
  );
SQL


def scrape db
  # http://citibikenyc.com/system-data
  response = HTTParty.get('http://citibikenyc.com/stations/json')

  response['stationBeanList'].each do |station|
    # save the station
    station_row = [
      station['id'],
      station['statusValue'],
      station['totalDocks'],
      station['latitude'],
      station['longitude'],
      station['stationName'],
      station['lastCommunicationTime']
    ]
    # this will ignore if the primary key already exists.
    # No need to update this data every single time, this won't change.
    db.execute("INSERT OR IGNORE INTO stations (id, status, total_docks, latitude, longitude, label, time) VALUES (?, ?, ?, ?, ?, ?, ?)", station_row)

    # only add the available count if the station is in service.
    # Otherwise its pretty pointless
    if (station['statusValue'] == "In Service")
      available_bikes_row = [
        station['id'],
        station['lastCommunicationTime'],
        station['availableBikes']
      ]
      db.execute("INSERT INTO available_bikes (station_id, time, count) VALUES (?, ?, ?)", available_bikes_row)
    end
  end
end

half_hour_in_secs = 60 * 30
ten_mins_in_secs = 60 * 10
sleep_duration = ten_mins_in_secs
loop do
  start = Time.new
  puts "Scraping more data at #{start}"

  scrape db
  # subtract the amount of time it took to actually scrape to maintain exactly
  # every half hour
  sleep sleep_duration - (Time.new - start)
end
