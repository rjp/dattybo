require 'rubygems'
require 'sinatra'
require 'dbi'
require 'haml'

get '/' do
    haml :index
end

get '/*/*' do
    splat = params['splat']
    username = splat[0]
    data, date = splat[1].split('/', 2)
    [splat, data, date].inspect
end
