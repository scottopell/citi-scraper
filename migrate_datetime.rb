require 'bundler/setup'
Bundler.require(:default, :test, :development)
require 'date'

db = SQLite3::Database.new('dev.db')
db.default_synchronous = 'OFF'

pairs = db.execute("SELECT station_id, time FROM available_bikes");
pairs.each_with_index do |pair, i|
  next if pair[1].is_a? Fixnum
  puts "#{i / pairs.length * 100}%" if ((i / pairs.length * 1000) % 1 != 0)

  d = DateTime.parse pair[1]
  db.execute("UPDATE available_bikes SET time = ? WHERE station_id = ? AND time = ?", d.strftime('%s'), [pair[0], pair[1]])
  #break
end
puts db.execute("SELECT station_id, time, date(time) FROM available_bikes LIMIT 10");
