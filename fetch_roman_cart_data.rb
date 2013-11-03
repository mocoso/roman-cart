#!/usr/bin/env ruby

# Run using ruby fetch_roman_cart_data.rb
#
# Fetches last n days worth of roman cart data and saves as into ./data/data.csv
require 'date'
require 'tmpdir'
require 'csv'

begin
  require 'rubygems'
  require 'mechanize'
rescue LoadError => e
  puts "This script requires mechanize to be installed. Install with\n\n    gem install mechanize\n"
  exit
end

class Array
  def pad(size, filler)
    while self.size < size
      self << filler
    end
  end
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

  def download_data_export(from_date, to_date, data_file_path, include_extra_data)
    export_form_page = agent.get("https://admin.romancart.com/v111/manage/salesman/exportsales.asp?#{session_query_string}")

    export_form = export_form_page.form_with(:name => 'expform')
    export_form.set_fields(
      :dateFrom   => from_date.strftime("%d-%b-%Y"),
      :dateTo     => to_date.strftime("%d-%b-%Y"),
      :exporttype => (include_extra_data ? 3 : 1),
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

    # Extract name of file from href, which will later be the name of the first file within the zip
    file_id = zip_link.href.split('/').last.split('.').first

    zip_file = zip_link.click
    zip_file.save_as tmp_zip_file

    puts "Unzip #{tmp_zip_file}"
    tmp_data_directory_path = File.join(Dir.tmpdir, file_id)
    system "unzip -o #{tmp_zip_file} -d #{tmp_data_directory_path}"

    if include_extra_data
      puts "Combining data files"
      downloaded_data = parse_download_data(tmp_data_directory_path)
      generate_combined_data_csv(data_file_path, downloaded_data)
    else
      puts "Rename to #{data_file_path}"
      FileUtils.mv(File.join(tmp_data_directory_path, "#{file_id}.csv"), data_file_path)
    end

    puts "Deleting #{tmp_data_directory_path}"
    system "rm -rf #{tmp_data_directory_path}"

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

    def parse_download_data(tmp_data_directory_path)
      downloaded_data = {}
      Dir.new(tmp_data_directory_path).each do |name|
        path = File.join(tmp_data_directory_path, name)
        if File.file?(path) && File.extname(path) == '.csv'
          csv = CSV.read(path)
          case csv[0][1].strip
          when 'companyname'
            downloaded_data['sales'] = csv
          when 'Extrafieldname'
            downloaded_data['extra_data'] = csv
          when 'itemcode'
            downloaded_data['items'] = csv
          else
            raise "Unrecognised CSV file"
          end
        end
      end
      downloaded_data
    end

    def generate_combined_data_csv(data_file_path, downloaded_data)
      items_input = downloaded_data['items']
      sales_input = downloaded_data['sales'] || raise("unable to identify sales file")
      extra_data_input = downloaded_data['extra_data'] ||  raise("unable to identify extra data file")

      CSV.open(data_file_path, "w") do |csv|
        items_input.each do |row|
          row = row.dup
          sales_id = row.shift.strip
          puts "processing #{sales_id} for #{row[1]}"
          row.pad(items_input[0].size - 1, '')
          csv << sales_output_row(sales_input, sales_id) + row + extra_data_output_row(extra_data_input, sales_id)
        end
      end
    end

    def sales_id_is_header_row?(sales_id)
      sales_id == 'salesmainid'
    end

    def sales_output_row(sales_input, sales_id)
      if sales_id_is_header_row?(sales_id)
        sales_input[0]
      else
        sales_input_row = sales_input.detect { |r| r[0].strip == sales_id } || raise("Missing sale information for sale with id #{sales_id}")
        output = sales_input_row.dup
        output.pad(sales_input[0].size, '')
        output
      end
    end

    def extra_data_output_row(extra_data_input, sales_id)
      if sales_id_is_header_row?(sales_id)
        ['Where did you first hear about Slug Rings?']
      else
        if extra_data_row = extra_data_input.detect { |r| r[0].strip == sales_id }
          extra_data_row.slice(2, 1)
        else
          ['']
        end
      end
    end
end

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
