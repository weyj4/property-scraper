require 'selenium-webdriver'
require 'nokogiri'

@dr = Selenium::WebDriver.for :firefox

@zips = [94102,94103,94104,94105,94107,94108,94109,94110,94111,94112,94114,94115,94116,94117,94118,94119,94120,94121,94122,94123,94124,94125,94126,94127,94128,94129,94130,94131,94132,94133,94134,94137,94139,94140,94141,94142,94143,94144,94145,94146,94147,94151,94158,94159,94160,94161,94163,94164,94172,94177,94188]

@addresses = []

def get_zillow(x)
  @dr.get('http://zillow.com/homes/' + x.to_s + '_rb')
  @dr.manage.window.maximize
end

def get_number_pages
  @dr.manage.window.maximize
  @number = @dr.find_element(:xpath, "//ol[contains(@class, 'zsg-pagination')]/li[last()-1]/a").text
end

def next_page
  @dr.find_element(:xpath, "//li[contains(@class, 'zsg-pagination-next')]/a").click
end

def get_houses
  (@number.to_i-1).times do
    soup = Nokogiri::HTML(@dr.page_source)
    houses = soup.xpath("//a[contains(@class, 'hdp-link routable')]")
    houses.each do |house|
      @addresses << house.text
      @addresses.map! do |address|
        address = address.gsub(',', '').gsub(/94.../, '').split(' ').join('-') 
      end
    end
    next_page
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
  @wait.until { @dr.find_element(:id, 'tp-fiveYears') }
  button = dr.find_element(:id, 'tp-fiveYears')
  dr.action.move_to(button).perform
  dr.action.click(button).perform
end

def cursor_move
  dr = @dr
  points = [100, 210, 330, 440, 550]
  el = dr.find_element(:id, 'chart')
  @prices = {}
  points.each do |point|
    dr.action.move_to(el,point,150).perform
    get_legend
    @prices[@month] = @legend
  end
end

def get_legend
  dr = @dr
  @wait.until { @dr.find_element(:class, 'legend-text') }
  dr.save_screenshot('1.png')
  @legend = @dr.find_element(:class, 'legend-value').text
  @month = @dr.find_element(:id, 'valueSeries').text
end


get_zillow(@zips[0])
get_number_pages
get_houses

@data = []

@addresses.each do |address|
  @array = []
  @array.push(address)
  go_to_page(address)
  get_zestimate
  @array.push(@zestimate)
  get_5yrs
  cursor_move
  @array.push(@prices)
  get_legend
  @array.push(@legend)
  @array.push(@month)
  @data.push(@array)
end



