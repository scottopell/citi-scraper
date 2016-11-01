require 'bundler/setup'
Bundler.require(:default, :test, :development)

db = SQLite3::Database.new('dev.db')

def prob_available db, station_id, target_dt
  day_of_week = target_dt.wday
  seconds_since_start_of_day = (target_dt.hour * 60 * 60) + (target_dt.minute * 60)
  query = <<-SQL
    SELECT
      AVG(count) / (SELECT total_docks FROM stations WHERE id = ?) as prob,
      strftime('%s', time),
      time
    FROM
      available_bikes
    WHERE
      strftime('%w', time) = CAST(? as text)
    AND
      abs(? - (strftime('%s', time) - strftime('%s', date(datetime(time, 'unixtime')), 'start of day'))) <= ?
  SQL
  # AND
      #abs(? - (strftime('%s', time) - date(datetime(time, 'unixtime'), 'start of day'))) <= ?

  twenty_mins_in_seconds = 20 * 60


  puts query
  #args = [station_id, day_of_week]
  args = [station_id, day_of_week, seconds_since_start_of_day, twenty_mins_in_seconds]
  puts args

  db.execute query, args
end

prob_available(db, 423, DateTime.parse('2016-10-27 10:58:46 PM')).each do |row|
  puts row
end
