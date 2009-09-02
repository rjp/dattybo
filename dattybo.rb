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

    @sql_range = [@days[0], @days[-1]]

    columns = []
    @data_vars = data_list.split(',')

    @info = Hash.new { |h,k| h[k] = {
        :type => 'counter',
        :graph => '',
        :data => {}
    }}
    @data_vars.each do |d|
        type = @dbh.select_one(
	        "select type from datatypes where name=? and datakey=?",
	        username, d
        )
        type = type || 'value'
        @info[d][:type] = type

        if type[0] == 'counter' then
            data = @dbh.select_all(
                "SELECT DATE(logged_at) AS logged_date,
		               COUNT(1) AS logged, MIN(value) AS min,
		               MAX(value) AS max, AVG(value) AS avg,
		               SUM(value) AS sum
		        FROM datalog
		        WHERE date(logged_at) between ? and ?
                AND name=? AND datakey=?
                GROUP BY DATE(logged_at)",
                [@days[0], @days[-1], username, d]
            )
            @info[d][:dump] = data.inspect
            data.each { |i|
                dt, ct, mn, mx, av, sm = i
                @info[d][:data][dt] = sm
            }
        end
    end

    haml :columns
end
