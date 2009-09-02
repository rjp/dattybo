require 'rubygems'
require 'sinatra'
require 'dbi'
require 'haml'
require 'daterange'

get '/' do
    haml :index
end

get '/*/*' do
    splat = params['splat']
    username = splat[0]
    data, date = splat[1].split('/', 2)
    days = daterange(date)
    [splat, data, date, days].inspect
end
