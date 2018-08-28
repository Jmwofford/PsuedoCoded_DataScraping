module DataSourcing
# module that organizes the functionality of the data thats being sourced

	module Jll
	    # organizes company (CBRE) that will hold all pertinent information for listings and properties- CBRE_info
		class Prop_Listing_Scraper

		uri = URI.parse("https://gewerbeimmobilien.jll.de/ergebnis/germany/gewerbe-einzelhandel/tenuretype-miete/")
		request = Net::HTTP::Get.new(uri)
		request["Upgrade-Insecure-Requests"] = "1"
		request["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36"
		request["Dnt"] = "1"
		request["X-Devtools-Emulate-Network-Conditions-Client-Id"] = "524AD8F9BCE7C613C7D81EFBF7025B0D"
		request["Referer"] = "https://gewerbeimmobilien.jll.de/einzelhandel/e0573/"

		req_options = {
		  use_ssl: uri.scheme == "https",
		}

		response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
		  http.request(request)
		end
		body = response.body
		# bulk of returned data for request
		



		end

	end

end
