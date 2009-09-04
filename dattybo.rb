require 'rubygems'
require 'sinatra'
require 'dbi'
require 'haml'
require 'daterange'
require 'gchart'

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
        :data => Hash.new,
        :last => Hash.new
    }}
    @data_vars.each do |d|
        type = @dbh.select_one(
	        "select type from datatypes where name=? and datakey=?",
	        username, d
        )
        type = type || 'value'
        @info[d][:type] = type
        chart_data = []

        if type[0] == 'counter' then
            data = @dbh.select_all(
                "SELECT DATE(logged_at) AS logged_date,
		               COUNT(1) AS logged, MIN(value) AS min,
		               MAX(value) AS max, AVG(value) AS avg,
		               SUM(value) AS sum, TIME(MAX(logged_at)) AS last
		        FROM datalog
		        WHERE date(logged_at) between ? and ?
                AND name=? AND datakey=?
                GROUP BY DATE(logged_at)",
                [@days[0], @days[-1], username, d]
            )
            @info[d][:dump] = data.inspect
            data.each { |i|
                dt, ct, mn, mx, av, sm, lt = i
                @info[d][:data][dt] = sm
                @info[d][:last][dt] = lt
            }
            @days.each { |i|
                x = @info[d][:data][i] || 0
                chart_data.push x
            }
        end

        gc = GChart.bar do |g|
            g.orientation = :vertical
            g.data = [chart_data]
            g.colors = ['#88aaff']
            g.width = 240
            g.height = 100

            g.axis(:left) { |a|
                a.range = 750..2000
                a.text_color = :black
                a.font_size = 9
            }

            g.axis(:bottom) do |a|
                a.range = 0..@days.size
                a.labels          = [@days[0], @days[-1]]
                a.label_positions = [0, @days.size-1]
                a.text_color = :black
                a.font_size = 9
            end
        end

        @info[d][:graph] = gc.to_url
        @info[d][:graph_data] = chart_data.inspect
    end

    haml :columns
end
