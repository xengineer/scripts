# - - coding: utf-8

require "nokogiri"

f = File.open("test.txt")

docs = Nokogiri::XML.parse(f)
#app_free_download = docs.css("tr td[class=\"app free\"] span:not[title=\"This App has In-App Purchases\"] span[class=\"oneline-info title-info\"] a")
app_free_download = docs.css("tr > td[class=\"app free\"]:first-child span[class=\"oneline-info title-info\"] a")
#app_free_grossing = docs.css("tr span a")
companies = docs.css("tr span[data-items]")

app_free_download.each { |game|
  p game.content
}

#companies.each { |company|
#  p company.content
#}
