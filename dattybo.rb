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

# http://chart.apis.google.com/chart?chxl=0:|2009-08-01|2009-08-11|2009-08-21|2009-08-31|1:|750|1000|1250|1500|2000&chxp=0,0.5,10.5,20.5,31.5|1,750,1000,1250,1500,2000&chxs=0,888888,9|1,888888,9,1,lt,cccccc&chs=240x100&chxt=x,y&chxtc=0,6|1,-220&chxr=1,750,2000,0|0,0,31,0&cht=bvg&chbh=a,0,0&chco=88CCFF&chds=750,2000&chd=<DATA>
# http://chart.apis.google.com/chart?chxs=0,000000,9%7C1,000000,9&chxt=y,x&chs=240x100&chxl=1:%7C2009-09-01%7C2009-09-30&cht=bvs&chco=%2388aaff&chxp=1,0,29&chd=e:qPmf..AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&chxr=0,750,2000%7C1,0,30
        gc = GChart.bar do |g|
            g.orientation = :vertical
            g.data = [chart_data]
            g.colors = ['#88aaff']
            g.width = 240
            g.height = 100
            g.min = 750
            g.max = 2000

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
