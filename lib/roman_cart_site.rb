require 'tmpdir'
require 'mechanize'
require 'roman_cart_export'

class RomanCartSite
  def initialize
    self.agent = Mechanize.new
  end

  def login(options)
    login_page = agent.get('https://admin.romancart.com')
    login_form = login_page.form_with(:name => 'frmlogin')
    login_form.set_fields(options)
    result_page = agent.submit(login_form, login_form.button_with(:value => 'Log In'))
    unless result_page.title == 'RomanCart - Logging in'
      raise('Unable to log in')
    end
    self.session_query_string = agent.history.last.uri.query
  end

  def data_export(from_date, to_date)
    export_form_page = agent.get("https://admin.romancart.com/v111/manage/salesman/exportsales.asp?#{session_query_string}")

    export_form = export_form_page.form_with(:name => 'expform')
    export_form.set_fields(
      :dateFrom   => from_date.strftime("%d-%b-%Y"),
      :dateTo     => to_date.strftime("%d-%b-%Y"),
      :exporttype => 3,
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

    if zip_link

      # GET data export file request -> getting the data
      tmp_zip_file = ::File.join(Dir.tmpdir, 'data.zip')
      puts "Download zip to #{tmp_zip_file}"

      zip_file = zip_link.click
      zip_file.save_as tmp_zip_file

      puts "Combining data files"
      data_export = RomanCartExport.new(tmp_zip_file).combined_data

      puts "Delete #{tmp_zip_file}"
      system "rm #{tmp_zip_file}"

      data_export
    else

      # There are no recent sales
      CSV.new ''
    end
  end

  private
  # This query appears to be part of the roman carts session info. Security
  # feature? Either way without it you get redirected back to the home page.
  attr_accessor :session_query_string

  attr_accessor :agent
end

