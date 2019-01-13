require 'array'
require 'csv'
require 'zip'

class RomanCartExport
  def initialize(zip_file)
    parse_download_data zip_file
  end

  def combined_data
    sales_csv || raise("unable to identify sales file")
    extra_csv || raise("unable to identify extra data file")

    items_csv.map do |item_row|
      combined_row(item_row)
    end
  end

  private
  attr_accessor :items_csv, :sales_csv, :extra_csv

  def combined_row(item_row)
    item_row = item_row.dup
    sales_id = item_row.shift.strip
    puts "processing #{sales_id} for #{item_row[1]}"
    item_row.pad(items_csv[0].size - 1, '')
    sales_output_row(sales_csv, sales_id) + item_row + extra_data_output_row(extra_csv, sales_id)
  end

  def parse_download_data(zip_file)
    Zip::File.open(zip_file) do |zip|
      zip.each do |entry|
        if entry.name.match(/\.csv$/)
          puts entry.name

          content = entry.get_input_stream.read.force_encoding('ISO-8859-1').encode('UTF-8')

          csv = CSV.parse(content)
          case csv[0][1].strip
          when 'companyname'
            self.sales_csv = csv
          when 'Extrafieldname'
            self.extra_csv = csv
          when 'itemcode'
            self.items_csv = csv
          else
            raise "Unrecognised CSV file"
          end
        end
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
      extra_data_header_row(extra_data_input)
    else
      extra_data_header_row(extra_data_input).map do |header|
        if extra_data_row = extra_data_input.detect { |r| r[0].strip == sales_id && r[1].strip == header }
          extra_data_row[2]
        else
          ''
        end
      end
    end
  end

  def extra_data_header_row(extra_data_input)
    extra_data_input.map { |r| r[1] }.drop(1).compact.map { |c| c.strip }.uniq
  end
end

