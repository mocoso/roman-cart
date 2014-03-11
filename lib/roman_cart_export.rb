require 'array'
require 'csv'
require 'zip/zipfilesystem'

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
    Zip::ZipFile.open(zip_file) do |files|
      files.each do |file|
        if file.name.match(/\.csv$/)
          csv = CSV.parse(file.get_input_stream)
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

