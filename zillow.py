from xlrd import open_workbook
from selenium import webdriver

dr = webdriver.PhantomJS()
addresses = []

def getAddresses():
  wb = open_workbook('properties.xlsx')
  ws = wb.sheet_by_name('2013Secured')
  num_rows = 1000
  curr_row = 0
  while curr_row < num_rows:
    curr_row += 1
    a = ws.cell_value(curr_row, 0)
    a = a.split( )
    hyph = '-'
    a = hyph.join(a)
    a = a + "-San-Francisco-CA_rb"
    addresses.append(a)

getAddresses()
found = 0

for address in addresses:
  dr.get('https://zillow.com/' + address)
  if dr.find_element_by_class_name('error-logo'):
    print address + " Not Found"
  else:
    print address + " Found"
    found += 1
    print "We found " + found + "addresss"




