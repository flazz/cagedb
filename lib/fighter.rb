require 'open-uri'
require 'nokogiri'
require 'json'

class Fighter
  attr_reader :doc, :url, :id

  def initialize url
    @doc = Nokogiri::HTML open(url)
    @url = url
    @id = url[%r{fighter/(.+)$}, 1]
  end

  def picture
    url = @doc.css("#fighter_picture img").first['src']
    open(url).read
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
                         t_str = col.content.strip

                         case t_str
                         when /\d+:\d+/
                           min, sec = t_str.split(':').map &:to_i
                           min * 60 + sec
                         else t_str
                         end

                       when :result
                         col.content.strip[/(\w+)$/, 1]
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

end
