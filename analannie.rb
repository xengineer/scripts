# - - coding: utf-8

require "nokogiri"
require "yaml"

unless ARGV[0].nil? then
end
if ARGV.size > 0 and ARGV[0] == "--inv"
  mode = "investigation"
end

config = YAML.load_file("company.yaml")
f = File.open("test.txt")

docs = Nokogiri::XML.parse(f)
app_free_download = docs.css("tr > td[class=\"app free\"]:first-child div[class=\"main-info\"]")

case mode
when "investigation" then
  app_free_download.each { |game|
    gname   = game.css("span[class=\"oneline-info title-info\"] a")
    company = game.css("span[class=\"oneline-info add-info\"] a")

    if !config.has_key?(company.text())
      print company.text() + ": \n"
    end
  }
else
  app_free_download.each { |game|
    gname   = game.css("span[class=\"oneline-info title-info\"] a")
    company = game.css("span[class=\"oneline-info add-info\"] a")
    if config.has_key?(company.text())
      print gname.text() + " " + company.text() + " " + config[company.text()] + "\n"
    else
      print gname.text() + " " + company.text() + " " + "unknown\n"
    end
  }
end
