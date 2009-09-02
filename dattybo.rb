require 'rubygems'
require 'sinatra'
require 'dbi'
require 'haml'
require 'daterange'

before do
    @dbh = DBI.connect('DBI:sqlite3:/home/rjp/.dattybo.db', '', '')
end

get '/' do
    haml :index
end

get '/*/*' do
    splat = params['splat']
    username = splat[0]
    data_list, date = splat[1].split('/', 2)
    @days = daterange(date)

    sql_range = [@days[0], @days[-1]]

    columns = []
    @data_vars = data_list.split(',')

    @info = Hash.new { |h,k| h[k] = {
        :type => 'counter',
        :graph => ''
    }}
    @data_vars.each do |d|
        type = @dbh.select_one(
	        "select type from datatypes where name=? and datakey=?",
	        username, d
        )
        type = type || 'value'
    end

    haml :columns
end
