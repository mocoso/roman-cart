#!/usr/local/bin/ruby

# Run using ruby fetch_roman_cart_data.rb
#
# Fetches last n days worth of roman cart data and saves as into ./data/data.csv
require 'date'
require 'tmpdir'

begin
  require 'rubygems'
  require 'mechanize'
rescue LoadError => e
  puts "This script requires mechanize to be installed. Install with\n\n    gem install mechanize\n"
  exit
end

class RomanCartSite

  def initialize
    @agent = Mechanize.new
  end

  def login(options)
    login_page = agent.get('https://admin.romancart.com')
    login_form = login_page.form_with(:name => 'frmlogin')
    login_form.set_fields(options)
    agent.submit(login_form)
    @session_query_string = agent.history.last.uri.query
  end

  def download_data_export(from_date, to_date, data_file_path)
    export_form_page = agent.get("https://admin.romancart.com/v111/manage/salesman/exportsales.asp?#{session_query_string}")

    export_form = export_form_page.form_with(:name => 'expform')
    export_form.set_fields(
      :dateFrom   => from_date.strftime("%d-%b-%Y"),
      :dateTo     => to_date.strftime("%d-%b-%Y"),
      :exporttype => 1,
      :sdelimiter => 1
    )

    # Choose to quote values in CSV (otherwise comma's in addresses cause problems)
    export_form.checkboxes.detect { |c| c.name = 'dblquotes' }.checked = true

    # Not sure why mechanize does not pick up these hidden fields which are in the form HTML
    # however setting them manually because it doesn't
    export_form.add_field!('posted', 'OK')
    args = session_query_string.split('=')
    export_form.add_field!(args.shift, args.join('='))
    exported_page = agent.submit(export_form)

    zip_link = exported_page.links.detect{ |l| l.text == 'here' }

    raise "Could not find file download link in response" unless zip_link

    # GET data export file request -> getting the data
    tmp_zip_file = ::File.join(Dir.tmpdir, 'data.zip')
    puts "Download zip to #{tmp_zip_file}"

    # Extract name of file from href, which will later be the name of the file within the zip
    file_id = zip_link.href.split('/').last.split('.').first

    zip_file = zip_link.click
    zip_file.save_as tmp_zip_file

    puts "Unzip #{tmp_zip_file}"
    system "unzip -o #{tmp_zip_file} -d #{Dir.tmpdir}"

    puts "Rename to #{data_file_path}"
    FileUtils.mv(File.join(Dir.tmpdir, "#{file_id}.csv"), data_file_path)

    puts "Delete #{tmp_zip_file}"
    system "rm #{tmp_zip_file}"
  end

  private
    # This query appears to be part of the roman carts session info. Security
    # feature? Either way without it you get redirected back to the home page.
    def session_query_string
      @session_query_string
    end

    def agent
      @agent
    end
end

config = YAML.load_file('config.yml')

days = (ARGV[0] || config['default_number_of_days']).to_i
to_date = Date.today
from_date = to_date - days

data_file_path = File.expand_path(config['download_to'])
FileUtils.makedirs File.dirname(data_file_path)

puts "Will fetch data from #{from_date} to #{to_date} and save to #{data_file_path}"

if File.exist?(data_file_path)
  puts "Deleting previous data file"
  File.delete(data_file_path)
end

site = RomanCartSite.new

puts 'Login'
site.login(config['login'])
puts 'Logged in'

site.download_data_export(from_date, to_date, data_file_path)
