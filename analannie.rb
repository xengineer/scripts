# - - coding: utf-8

require "nokogiri"

f = File.open("test.txt")

docs = Nokogiri::XML.parse(f)
#app_free_download = docs.css("tr td[class=\"app free\"] span:not[title=\"This App has In-App Purchases\"] span[class=\"oneline-info title-info\"] a")
#app_free_download = docs.css("tr > td[class=\"app free\"]:first-child div[class=\"main-info\"] span[class=\"oneline-info title-info\"] span[class=\"oneline-info add-info\"] a")
#app_free_download = docs.css("tr > td[class=\"app free\"]:first-child div[class=\"main-info\"] span a")
app_free_download = docs.css("tr > td[class=\"app free\"]:first-child div[class=\"main-info\"]")
#app_free_grossing = docs.css("tr span a")
companies = docs.css("tr span[data-items]")

app_free_download.each { |game|
  gname   = game.css("span[class=\"oneline-info title-info\"] a")
  company = game.css("span[class=\"oneline-info add-info\"] a")
  p gname.text()
  p company.text()
  print "\n"
}

