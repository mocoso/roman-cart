require_relative '../../web'
require 'webmock/rspec'
require 'rack/test'
require 'timecop'

describe 'fetching data' do
  include Rack::Test::Methods

  before { Timecop.freeze(Time.parse('1pm, 15th Jan, 2014')) }

  def app
    Sinatra::Application
  end

  it 'fetches my data from roman cart when there have been recent sales' do
    given_a_stubbed_roman_cart_site
    and_recent_sales
    when_i_request_the_customer_data
    then_i_get_the_combined_data_as_a_csv
  end

  it 'fetches an empty csv from roman cart when there are no recent sales' do
    given_a_stubbed_roman_cart_site
    and_no_recent_sales
    when_i_request_the_customer_data
    then_i_get_an_empty_csv
  end

  let(:from_date) { Date.civil(2014, 1, 1) }
  let(:to_date) { Date.civil(2014, 1, 15) }
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
            <input type="submit" value="Log In">
          <form>},
        :headers => { 'Content-Type' => 'text/html' }
      )

    stub_request(:post, "https://admin.romancart.com/v111/menu.asp").
      with(:body => {"password" => password, "storeid" => store_id, "username" => user_name}).
      to_return(:status => 302, :body => "", :headers => { 'Location' => 'https://admin.romancart.com/v111/menu.asp?crx=foo&kxr=bar' })

    stub_request(:get, "https://admin.romancart.com/v111/menu.asp?crx=foo&kxr=bar").
      to_return(
        :status => 200,
        :body => "<html><head><title>RomanCart - Logging in</title></head></html>",
        :headers => { 'Content-Type' => 'text/html'}
      )

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
  end

  def and_recent_sales
    stub_request(:post, "https://admin.romancart.com/v111/manage/salesman/exportsales.asp").
      with(:body => {"crx"=>"foo&kxr=bar", "dateFrom"=>"01-Jan-2014", "dateTo"=>"15-Jan-2014", "dblquotes"=>"on", "exporttype"=>"3", "posted"=>"OK", "sdelimiter"=>"1"}).
      to_return(:status => 200, :body => %q{Download <a href="34046uzqctgf66.zip">here</a>}, :headers => { 'Content-Type' => 'text/html' })

    stub_request(:get, "https://admin.romancart.com/v111/manage/salesman/34046uzqctgf66.zip").
      to_return(:status => 200, :body => File.new('spec/data/sample_roman_cart_data.zip'), :headers => { 'Content-Type' => 'application/zip' })
  end

  def and_no_recent_sales
    stub_request(:post, "https://admin.romancart.com/v111/manage/salesman/exportsales.asp").
      with(:body => {"crx"=>"foo&kxr=bar", "dateFrom"=>"01-Jan-2014", "dateTo"=>"15-Jan-2014", "dblquotes"=>"on", "exporttype"=>"3", "posted"=>"OK", "sdelimiter"=>"1"}).
      to_return(:status => 200, :body => %q{No link for data}, :headers => { 'Content-Type' => 'text/html' })
  end

  def when_i_request_the_customer_data
    @response = post('/export.csv', :user_name => user_name, :password => password, :store_id => store_id)
  end

  def then_i_get_the_combined_data_as_a_csv
    expect(@response.headers['Content-Type']).to eq('text/csv')
    reference_csv = CSV.read('spec/data/sample_output.csv')
    expect(CSV.parse(@response.body)).to eq(reference_csv)
  end

  def then_i_get_an_empty_csv
    expect(@response.headers['Content-Type']).to eq('text/csv')
    reference_csv = []
    expect(CSV.parse(@response.body)).to eq(reference_csv)
  end
end


