#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path('lib'))

# Run using ruby fetch_roman_cart_data.rb
#
# Fetches last n days worth of roman cart data and saves as into ./data/data.csv
require 'date'
require 'roman_cart_site'


config = YAML.load_file('config.yml')

to_date = Date.today
from_date = to_date - config['number_of_days'].to_i

data_file_path = File.expand_path(config['download_to'])
FileUtils.makedirs File.dirname(data_file_path)

puts "Will fetch data#{' including extra data' if config['include_extra_data']} from #{from_date} to #{to_date} and save to #{data_file_path}"

if File.exist?(data_file_path)
  puts "Deleting previous data file"
  File.delete(data_file_path)
end

site = RomanCartSite.new

puts 'Login'
site.login(config['login'])
puts 'Logged in'

site.download_data_export(from_date, to_date, data_file_path, config['include_extra_data'])
