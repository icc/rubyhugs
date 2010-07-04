require 'open-uri'
require 'json'
require 'xmlsimple'

class Weather
  attr_reader :triggers

  def initialize
    @triggers = Array.new
    @triggers << [:channel, /^!weather(.*)/, Proc.new { msg channel, $modules['weather'].weather(nick, match[0]) rescue nil }]
  end

  def weather(nick, place)
    $DB.create_table :weather_defaults do
      primary_key :id
      String :nick
      String :place
    end unless $DB.table_exists? :weather_defaults

    place = place.gsub(/ /,'')
    default = $DB[:weather_defaults].filter(:nick => nick).first
    unless place == ''
      if default.nil?
        $DB[:weather_defaults].insert(:nick => nick, :place => place)
      else
        $DB[:weather_defaults].filter(:nick => nick).update(:place => place)
      end
    else
      if default.nil?
        place = 'Oslo'
      else
        place = default[:place]
      end
    end
    find(place)
  end

  def fetch_report(url)
    begin
      buffer = open(url).read
      data = XmlSimple.xml_in(buffer, { 'KeyAttr' => 'name' })
      return data["channel"][0]["item"][0]["description"][0]
    rescue
      return nil
    end
  end

  def find(place)  
    return "Sorry, I can only get the first 5 hits." if place.to_i > 5 or place.to_i < 0

    url = 'http://www.yr.no/_/websvc/jsonforslagsboks.aspx?s=' + URI.escape(place.gsub(/#{place.to_i}/, ''))
    begin
      buffer = open(url).read
      result = JSON.parse(buffer.gsub(/(,,)/, ',"",""'))
    rescue
      return "Sorry, the weather service seems to be down."
    end

    (5 - place.to_i).times do |i|
      i += place.to_i
      result[1][i][1] = result[1][i][1] + result[1][i][0] + '/' until result[1][i][1].split('/').size == 6 if result[1][i][3] == 'NO'
      url = 'http://www.yr.no' + URI.escape(result[1][i][1]) +'/varsel.rss'
      report = fetch_report(url)
      return "#{result[1][i][0]}, #{result[1][i][2]}: #{report}" unless report.nil?
    end unless result[1][1].nil?  

    return "Sorry, no weather report for \"#{place}\"."
  end
end
