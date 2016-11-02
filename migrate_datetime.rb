require 'bundler/setup'
Bundler.require(:default, :test, :development)
require 'date'

db = SQLite3::Database.new('dev.db')
db.default_synchronous = 'OFF'

conn = PG.connect( dbname: 'citibike', port: 5433 )

rows = db.execute("SELECT station_id, time, count FROM available_bikes");

puts "Before count: "
puts conn.exec("SELECT count(*) from available_bikes;").first["count"]

rows.each_with_index do |row, i|
  d = nil
  if row[1].is_a? Fixnum
    d = Time.at(row[1]).to_datetime
  else
    d = DateTime.parse row[1]
  end

  query = <<-SQL
    INSERT INTO available_bikes
    (station_id, time, count)
    VALUES
    ($1, $2, $3)
  SQL
  conn.exec_params query, [row[0], d, row[2]]
end

puts "After count: "
puts conn.exec("SELECT count(*) from available_bikes;").first["count"]
