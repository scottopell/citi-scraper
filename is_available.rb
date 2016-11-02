require 'bundler/setup'
Bundler.require(:default, :test, :development)

conn = PG.connect( dbname: 'citibike', port: 5433 )

def prob_available conn, station_id, target_dt
  day_of_week = target_dt.wday
  seconds_since_start_of_day = (target_dt.hour * 60 * 60) + (target_dt.minute * 60)

  # dow means "day of week", returns 0 for sunday, 1 for monday, etc.
  # extract (epoch from time::time) is pretty gnarly.
  # "time" is the name of the column in available_bikes, and also a postgres
  # type. So say we called our column "mycooltime" instead, this would
  # read extract(epoch from mycooltime::time)
  #
  # What this does is cast the datetime (timestamp? not sure on my postgres
  # terminology) as a time, effectively removing the "date" portion of the
  # datetime. So then converting that value to an "epoch" means converting it
  # to seconds. which is the goal here, because then we neatly compare it to
  # our target datetime.
  #
  # TODO fix this so that it checks the probability that at least 1 bike is
  # available, not the avg ratio of available bikes.
  query = <<-SQL
    SELECT
      AVG(count) / (SELECT total_docks FROM stations WHERE id = $1) as prob
    FROM
      available_bikes
    WHERE
      extract(dow from time) = $2
    AND
      abs($3 - extract(epoch from time::time)) <= $4
  SQL

  twenty_mins_in_seconds = 20 * 60

  args = [station_id, day_of_week, seconds_since_start_of_day, twenty_mins_in_seconds]

  conn.exec_params(query, args).first["prob"]
end

puts prob_available(conn, 423, DateTime.parse('2016-11-1 10:58:46 AM'))
