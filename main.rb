require "./src/SIA.rb"
require "json"

sia_config = open("./config.json") do |io|
    JSON.load(io)
end
  
sia = SIA.new(sia_config['Token'],sia_config['Prefix'])
sia.run