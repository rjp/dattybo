require 'date'
require 'parsedate'

def daterange(start)
    output = []
    sd_list = ParseDate.parsedate(start)
    sd_set = sd_list.reject{|x|x.nil?}
    sd_check = sd_set.join('-')
    sd = Date.parse(start)
    loop do
        nd_list = ParseDate.parsedate(sd.to_s)
        nd_check = nd_list[0..sd_set.size-1].join('-')
        if (nd_check != sd_check) then
            break
        end
        output.push sd.to_s
        sd = sd.succ
    end
    return output
end

if (0) then
ARGV.each {|x|
    puts "#{x}: " << daterange(x).inspect
}
end
