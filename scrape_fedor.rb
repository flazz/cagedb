require 'open-uri'
require 'nokogiri'
require 'json'

class Fighter

  def initialize url
    @url = url
    @doc = Nokogiri::HTML open(url)
  end

  def record
    fields = [:result, :opponent, :method, :event, :date, :round, :time]

    table = @doc.css("#fighter_stat table").first
    rows = table.css('tr')
    rows.shift

    rows.inject([]) do |list, row|

      fight = {}
      row.css('td').each_with_index do |col, i|
        field = fields[i]

        fight[field] = case field
                       when :opponent
                         fight[:opponent_link] = col.css('a').first['href'].strip
                         col.content.strip
                       when :event
                         fight[:event_link] = col.css('a').first['href'].strip
                         col.content.strip
                       when :round then col.content.strip.to_i
                       when :date then Date.parse col.content.strip
                       when :time
                         min, sec = col.content.strip.split(':').map &:to_i
                         min * 60 + sec
                       when :result
                         col.content.strip[/^..(Win|Loss)$/, 1]
                       else
                         col.content.strip
                       end

      end

      list << fight
    end

  end

  def profile
    table = @doc.css("#fighter_profile table").first
    table.css('tr').inject({}) do |acc, row|
      name, value = row.css('td').map { |td| td.content.strip }
      name.downcase!

      unless %(record wins losses sherdog\ store).include? name

        acc[name] = case name
                    when 'height' then value[/\((\d+)cm\)/, 1].to_i
                    when 'weight' then value[/\((\d+)kg\)/, 1].to_i
                    when 'birth date' then Date.parse value
                    else value
                    end

      end

      acc
    end

  end

  def to_json *a
    { :link => @url,
      :profile => profile,
      :record => record
    }.to_json *a
  end

end

f = Fighter.new 'http://www.sherdog.com/fighter/Vitor-Belfort-156'
puts f.to_json
