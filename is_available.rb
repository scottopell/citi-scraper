require 'bundler/setup'
Bundler.require(:default, :test, :development)

conn = PG.connect(dbname: 'citibike', port: 5433)

def prob_available(conn, station_id, target_dt)
  day_of_week = target_dt.wday
  seconds_since_start_of_day = (target_dt.hour * 60 * 60) + (target_dt.minute * 60)

  # dow means "day of week", returns 0 for sunday, 1 for monday, etc.
  # extract (epoch from time::time) is pretty gnarly.
  # "time" is the name of the column in available_bikes, and also a postgres
  # type. So say we called our column "mycooltime" instead, this would
  # read extract(epoch from mycooltime::time)
  #
  # What this does is cast the datetime as a time, effectively removing the
  # "date" portion of the datetime. So then converting that value to an "epoch"
  # means converting it to seconds. which is the goal here, because then we
  # neatly compare it to our target datetime.
  spots_available_query = <<-SQL
    SELECT
      COUNT(*) as spots_available
    FROM
      available_bikes
    WHERE
      count > 2
    AND
      station_id = $1
    AND
      extract(dow from time) = $2
    AND
      abs($3 - extract(epoch from time::time)) <= $4
  SQL

  total_records_query = <<-SQL
    SELECT
      COUNT(*) as total_records
    FROM
      available_bikes
    WHERE
      station_id = $1
    AND
      extract(dow from time) = $2
    AND
      abs($3 - extract(epoch from time::time)) <= $4
  SQL

  twenty_mins_in_seconds = 20 * 60

  args = [station_id, day_of_week, seconds_since_start_of_day, twenty_mins_in_seconds]

  spots_available_results = conn.exec_params(spots_available_query, args)
  total_records_results = conn.exec_params(total_records_query, args)

  spots_available = spots_available_results.first['spots_available'].to_i
  total_records = total_records_results.first['total_records'].to_i

  spots_available.to_f / total_records
end

# Example Usage
#d_str = '2016-11-1 09:58:46 AM'
#puts d_str
#puts prob_available(conn, 423, DateTime.parse(d_str))

get '/prob_available' do
  prob_available(conn, params['station_id'], DateTime.parse(params['target_dt'])).to_s
end

get '/' do
  haml :index
end
