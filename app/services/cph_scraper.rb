require 'nokogiri'
require 'pry'
require 'json'
require 'date'
require 'open-uri'

# Will be used to scrap the CPH urls
class CphScraper
  attr_reader :departure_url, :arrival_url, :date

  def initialize
    @departure_url = Departure::CPH_URL
    @arrival_url = Arrival::CPH_URL
    @date = Date.current
  end

  def execute
    set_departures_for_3_days
    set_arrivals_for_3_days
  end

  private

  def set_departures_for_3_days
    set_departures(departure_url, date)
    set_departures(departure_url, date + 1)
  end

  def set_arrivals_for_3_days
    set_arrivals(departure_url, date)
    set_arrivals(departure_url, date + 1)
  end

  def set_departures(url, date_param)
    parse_page = Nokogiri::HTML(open(url + "?date=#{date_param}")) rescue nil
    return if parse_page.nil?

    table = parse_page.at('#flightFirstTable')
    data_rows = table.css('.stylish-table__row--body')
    data_rows.each do |row|
      departure = Departure.where(
        date:           date_param,
        airline:        row.css('.v--desktop-only')[1].at('span')&.text,
        flight_no: row.at('.flights__table__col--destination').css('small')&.text
      ).first_or_initialize

      departure.time        = row.at('.flights__table__col--time').search('span')[0]&.text
      departure.expected    = row.css('.v--desktop-only')[0].at('span')&.text
      departure.destination = row.at('.flights__table__col--destination').css('strong')&.text
      departure.gate        = row.at('.flights__table__col--gate').at('span')&.text
      departure.terminal    = row.at('.flights__table__col--terminal').at('span')&.text
      departure.status      = row.css('.stylish-table__cell')[6].at('span')&.text
      departure.save
    end
  end

  def set_arrivals(url, date_param)
    parse_page = Nokogiri::HTML(open(url + "?date=#{date_param}")) rescue nil
    return if parse_page.nil?

    table = parse_page.at('#flightFirstTable')
    data_rows = table.css('.stylish-table__row--body')
    data_rows.each do |row|
      arrival = Arrival.where(
        date:             date_param,
        airline:          row.css('.v--desktop-only')[1].at('span')&.text,
        arriving_from:    row.at('.flights__table__col--destination').css('strong')&.text,
        flight_no: row.at('.flights__table__col--destination').css('small')&.text
      ).first_or_initialize
      arrival.tid           = row.at('.flights__table__col--time').search('span')[0]&.text
      arrival.expected      = row.css('.v--desktop-only')[0].at('span')&.text
      arrival.arriving_from = row.at('.flights__table__col--destination').css('strong')&.text
      arrival.gate          = row.at('.flights__table__col--gate').at('span')&.text
      arrival.terminal      = row.at('.flights__table__col--terminal').at('span')&.text
      arrival.status        = row.css('.stylish-table__cell')[6].at('span')&.text
      arrival.save
    end
  end

  def get_date(str)
    Date.parse(str) rescue Date.current
  end
end
