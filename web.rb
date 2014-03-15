$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'sinatra'
require 'roman_cart_site'

enable :logging

post '/export.csv' do
  headers['Content-Type'] = 'text/csv'

  site = RomanCartSite.new
  site.login('storeid' => params[:store_id], 'username' => params[:user_name], 'password' => params[:password])
  date_export = site.data_export(Date.today - 7, Date.today)
  CSV.generate { |csv| date_export.each { |r| csv << r } }
end
