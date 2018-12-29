$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'sinatra'
require 'roman_cart_site'

enable :logging

get '/' do
  'Reqests should be posted to export.csv'
end

post '/export.csv' do
  headers['Content-Type'] = 'text/csv'

  site = RomanCartSite.new
  site.login('storeid' => params[:store_id], 'username' => params[:user_name], 'password' => params[:password])
  date_export = site.data_export(Date.today - 14, Date.today)
  CSV.generate { |csv| date_export.each { |r| csv << r } }
end
