require 'ruby-debug'
require 'set'
require 'open-uri'
require 'nokogiri'

$urls = {}

def print_record url
  return if $urls[url]

  puts url.inspect
  doc = Nokogiri::HTML open(url)
  $urls[url] = true

  min_col_set = %w(Result Opponent Method Date Round Time).to_set

  table = doc.css("h2:contains('Mixed martial arts record') ~ table",
                  "h2:contains('MMA records') ~ table").find do |table|
    headers = table.css("th", 'td').map { |col| col.content }
    headers.to_set.superset? min_col_set
  end

  rows = table.css("tr")
  headings = rows.shift.css('th', 'td').map { |h| h.content }

  # the list of fights
  records = []

  records = rows.map do |row|
    record = {}

    row.css('td').each_with_index do |col, i|
      heading = headings[i]

      if heading == "Opponent" and col.css('a')
        record['url'] = "http://en.wikipedia.org#{col.css('a').last['href']}"
      end

      record[heading] = col.content
    end

    record
  end

  puts doc.css('h1').first.content

  records.each do |r|
    puts r.values_at('Result', 'Opponent', 'Round', 'Time').join("\t")
  end

  puts
  records.select { |r| r['url'] }.each { |r| print_record r['url'] }
end

class Fighter

  def initialize url
    @doc = Nokogiri::HTML open(url)
  end

  def stats
    fields = [:result, :opponent, :method, :event, :date, :round, :time]

    table = @doc.css("#fighter_stat")
    rows = table.css('tr')
    rows.shift

    rows.inject([]) do |list, row|

      fight = {}
      row.css('td').each_with_index do |col, i|

        fight[ fields[i] ] = if [:opponent, :event].include? fields[i]
                               { :link => col.css('a').first['href'].strip,
                                 :name => col.content.strip }
                             else
                               col.content.strip
                             end

      end

      list << fight
    end

  end

end

f = Fighter.new 'http://www.sherdog.com/fighter/Vitor-Belfort-156'
require 'pp'
pp f.stats
