require 'roman_cart_site'
require 'webmock/rspec'

describe 'fetching data' do
  it 'fetches my data from roman cart' do
    given_a_stubbed_roman_cart_site
    when_i_request_the_customer_data
    then_i_get_the_data_as_a_single_csv
  end

  let(:from_date) { Date.civil(2014, 1, 1) }
  let(:to_date) { Date.civil(2014, 1, 8) }
  let(:include_extra_data) { true }
  let(:data_file_path) { 'spec_data.csv' }
  let(:store_id) { '11111' }
  let(:user_name) { 'joe@acme.test' }
  let(:password) { 'super-secret' }

  def given_a_stubbed_roman_cart_site
    stub_request(:get, "https://admin.romancart.com/").
      to_return(
        :status => 200,
        :body => %q{<form name="frmlogin" method="post" action="https://admin.romancart.com/v111/menu.asp">
            <input type="text" name="storeid">
            <input type="text" name="username">
            <input type="password" name="password">
          <form>},
        :headers => { 'Content-Type' => 'text/html' }
      )

    stub_request(:post, "https://admin.romancart.com/v111/menu.asp").
      with(:body => {"password" => password, "storeid" => store_id, "username" => user_name}).
      to_return(:status => 302, :body => "", :headers => { 'Location' => 'https://admin.romancart.com/v111/menu.asp?crx=foo&kxr=bar' })

    stub_request(:get, "https://admin.romancart.com/v111/menu.asp?crx=foo&kxr=bar").
      to_return(:status => 200, :body => "", :headers => {})

    stub_request(:get, "https://admin.romancart.com/v111/manage/salesman/exportsales.asp?crx=foo&kxr=bar").
      to_return(
        :status => 200,
        :body => %q{
          <form name="expform" action="exportsales.asp" method="post">
            <input id="dateFrom" name="dateFrom" type="text">
            <input id="dateTo" name="dateTo" type="text">
            <select name="exporttype">
              <option selected="" value="1">Single File</option>
              <option value="2">Summary and Item files</option>
              <option value="3">Summary, Item and Extra field files</option>
            </select>
            <select name="sdelimiter">
              <option selected="" value="1">,</option>
              <option value="2">|</option>
            </select>
            <input type="checkbox" name="dblquotes">
          </form>
        },
        :headers => { 'Content-Type' => 'text/html' }
      )
    stub_request(:post, "https://admin.romancart.com/v111/manage/salesman/exportsales.asp").
      with(:body => {"crx"=>"foo&kxr=bar", "dateFrom"=>"01-Jan-2014", "dateTo"=>"08-Jan-2014", "dblquotes"=>"on", "exporttype"=>"3", "posted"=>"OK", "sdelimiter"=>"1"}).
      to_return(:status => 200, :body => %q{Download <a href="34046uzqctgf66.zip">here</a>}, :headers => { 'Content-Type' => 'text/html' })

    stub_request(:get, "https://admin.romancart.com/v111/manage/salesman/34046uzqctgf66.zip").
      to_return(:status => 200, :body => File.new('spec/data/sample_roman_cart_data.zip'), :headers => { 'Content-Type' => 'application/zip' })
  end

  def when_i_request_the_customer_data
    site = RomanCartSite.new
    site.login('storeid' => store_id, 'username' => user_name, 'password' => password)
    site.download_data_export(from_date, to_date, data_file_path, include_extra_data)
  end

  def then_i_get_the_data_as_a_single_csv
    output_csv = CSV.read(data_file_path)
    reference_csv = CSV.read('spec/data/sample_output.csv')
    expect(output_csv).to eq(reference_csv)
  end
end


