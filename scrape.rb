require 'selenium-webdriver'
require 'nokogiri'
require 'csv'

@dr = Selenium::WebDriver.for :firefox

@zips = [94102,94103,94104,94105,94107,94108,94109,94110,94111,94112,94114,94115,94116,94117,94118,94119,94120,94121,94122,94123,94124,94125,94126,94127,94128,94129,94130,94131,94132,94133,94134,94137,94139,94140,94141,94142,94143,94144,94145,94146,94147,94151,94158,94159,94160,94161,94163,94164,94172,94177,94188]

@addresses = []

def get_zillow(x)
  @dr.get('http://zillow.com/homes/' + x.to_s + '_rb')
  @dr.manage.window.maximize
end

def get_number_pages
  @dr.find_element(:id, "listings-menu-label").click
  @dr.find_element(:xpath, "//li[contains(@id, 'rs-listings')]/div/label/span[contains(@class, 'listing-type-text')]").click
  sleep 5
  @number = @dr.find_element(:xpath, "//ol[contains(@class, 'zsg-pagination')]/li[last()-1]/a").text
end

def next_page
  url = @url.split(/\//).insert(9, @x.to_s + "_p").join('/')
  @dr.get(url)
end

def get_houses
  @url = @dr.current_url
  @x = 1
  (@number.to_i-1).times do
    soup = Nokogiri::HTML(@dr.page_source)
    @houses = soup.xpath("//a[contains(@class, 'hdp-link routable')]")
    @houses.each do |house|
      @addresses << house.text
      @addresses.map! do |address|
        address = address.gsub(',', '').gsub(/94.../, '').split(' ').join('-') 
      end
    end
    @x = @x += 1
    next_page
    @addresses = @addresses.uniq
  end
end

@wait = Selenium::WebDriver::Wait.new(:timeout => 15)

def go_to_page(x)
  dr = @dr
  address = x.split(' ').join('-')
  dr.get "http://zillow.com/homes/" + address + "_rb/"
end

def get_zestimate
  dr = @dr
  if dr.find_elements(:class, 'zest-value').length > 0
    zest = dr.find_element(:class, 'zest-value')
    @zestimate = zest.text
  else
    @zestimate = "N/A"
  end
end

def get_5yrs
  dr = @dr
  begin
    @wait.until { @dr.find_element(:id, 'tp-fiveYears') }
    button = dr.find_element(:id, 'tp-fiveYears')
    dr.action.move_to(button).perform
    dr.action.click(button).perform
  rescue
    return false
  end
end

def cursor_move
  dr = @dr
  el = dr.find_element(:id, 'chart')
  @prices = {}
  x = 0
  while x < 600
    dr.action.move_to(el,x,150).perform
    get_legend
    @month = dr.find_element(:id, 'valueSeries')
    if @month.text =~ /Feb(.*)/
      month = @month.text
      @prices[month] = @legend
    end
    x += 10
  end
end

def get_legend
  dr = @dr
  @wait.until { dr.find_element(:class, 'legend-text') }
  @legend = dr.find_element(:class, 'legend-value').text
end

def get_comp
  dr = @dr
  begin
    @wait.until { dr.find_element(:xpath, "//section[contains(@class, 'zsg-content-section')]/h3") }
    comps = dr.find_element(:xpath, "//section[contains(@class, 'zsg-content-section')]/h3").text
    @comp = comps.split(' ').last
  rescue
    return false
  end
end


get_zillow(@zips[1])
get_number_pages
get_houses

puts @addresses.length


@addresses.each do |address|
  @array = []
  @array.push(address)
  go_to_page(address)
  get_zestimate
  @array.push(@zestimate)
  get_5yrs
  if get_5yrs == false
    puts "not found"
  else
    cursor_move
    @prices.each do |el|
      @array.push(el)
    end
    get_legend
  end
  if get_comp == false
    puts "not found"
  else
    get_comp
    @array.push(@comp)
  end
  CSV.open("94103.csv", "ab") do |csv|
    csv << @array
  end
  puts @array
end



