module DataSourcing
  # module that organizes the functionality of the data thats being sourced
  module Cbre
    # organizes company (CBRE) that will hold all pertinent information for listings and properties- CBRE_info
    class ListingScraper
      # specific class for developing listings
      def self.call
        # defines self as method, acts similar to a callback and takes web request [curl] and converts into ruby syntax
        uri = URI.parse("https://www.gewerbeimmobilien.cbre.de/api/propertylistings/query?Site=de-comm&Interval=Monthly&Unit=sqm&CurrencyCode=EUR&RadiusType=Kilometers&Common.HomeSite=de-comm&radius=531.3260120498461&Lat=51.165691&Lon=10.451526000000058&Common.Aspects=isLetting&PageSize=200&Page=1&Sort=asc(_distance)&Common.UsageType=Industrial&_select=Dynamic.PrimaryImage,Common.ActualAddress,Common.Charges,Common.NumberOfBedrooms,Common.PrimaryKey,Common.Coordinate,Common.Aspects,Common.ListingCount,Common.IsParent,Common.ContactGroup,Common.Highlights,Common.Walkthrough,Common.MinimumSize,Common.MaximumSize,Common.TotalSize,Common.GeoLocation,Common.Sizes")
        request = Net::HTTP::Get.new(uri)
        request["Cookie"] = "has_js=1; _ga=GA1.2.1872514242.1532982989; cookie_message=1; mf_user=9800922091cbdd73c0a13ea1b76e6002|; ai_user=hKicW|2018-08-23T19:24:39.874Z; _gid=GA1.2.113648017.1535409130; mf_21f05a9d-2fac-48a7-91af-ee0c6bd37350=6288821e7c64c04a7e4c993ce02abbcb|082001313485a6f3886a35ae0c46a0d920de1e2a.6019281252.1534800601595,082305387d2e31a0b5a009c6f3bd1acfb7920f97.47.1535052186199,08231354925ee687e7e67f75310ee27a26df4478.48408.1535052254049,0823180049ac551b64f563dbb0f92850b52990b4.4270391946.1535052268972,082710791b2d33a3319a2e79dc1b243fab18ca7c.47.1535409130582|1535409886568||1|||0|15.13; ADRUM=s=1535409886568&r=https%3A%2F%2Fwww.cbre.de%2F%3F0; ai_session=B6Ixg|1535409884795|1535409930199.9; _gat=1"
        request["Accept-Language"] = "en-US,en;q=0.9,de;q=0.8"
        request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36"
        request["Accept"] = "application/json, text/javascript, */*; q=0.01"
        request["Referer"] = "https://www.gewerbeimmobilien.cbre.de/de-DE/listings/logistikimmobilien/results?CurrencyCode=EUR&Interval=Monthly&RadiusType=Kilometers&Site=de-comm&Unit=sqm&aspects=isLetting&lat=51.165691&location=Deutschland&lon=10.451526000000058&placeId=ChIJa76xwh5ymkcRW-WRjmtd6HU&searchMode=bounding&usageType=Industrial"
        request["X-Requested-With"] = "XMLHttpRequest"
        request["Connection"] = "keep-alive"
        request["Request-Id"] = "|5oAKr./ob+t"

        req_options = {
          use_ssl: uri.scheme == "https",
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
        body = response.body
        # variabalized instance of the "body" of web request
        json_results = JSON.parse body
        # body of request data converted into JSON to be parsed
        results = json_results["Documents"].first
        # json (parsed) results -- under the Documents key--returning the first hash of arrays/ objects

        results.each do |listing_array|
          # each json result mapped into a single listings_array instance to demand implicit return
          url = listing_url(listing_array)
          # url of each available listing array..variable
          unique_listing_id = listing_array["Common.PrimaryKey"]
          # id of listing..displaed as key within listing_array
          listing = Listing.find_or_initialize_by(url: url, unique_listing_id: unique_listing_id)
          # find listing with specific params(url/uniqueId), if listing not found with params, create/init listing with params
          property = Property.find_or_initialize_by(
            # specifically search properties by params(lat&lon), if none found, instantiate new property with given params
            latitude: listing_array["Common.Coordinate"]["lat"],
            longitude: listing_array["Common.Coordinate"]["lon"])
          property.update(address: address(listing_array))
          property.save
          # update property with new address info..if info hadnt changed == nil. Save propery_attr(address) to db
          listing.update(property: property)
          # update listing based on new property info 
        end
        nil
        #  ??? not sure why nil is here ??? 
      end

      def self.listing_url(listing_array)
        url_start = "https://www.gewerbeimmobilien.cbre.de/de-DE/listings/logistikimmobilien/details/"
        primary_key = listing_array["Common.PrimaryKey"]
        # primary identifier for listing array..will be paire with other attrs to form listing
        address = listing_array["Common.ActualAddress"]
        postcode = address["Common.PostCode"]
        locality = address["Common.Locallity"]

        # weird_case
        # "Halle (Saale)/Brachstedt" must become "halle-saalebrachstedt"
        final_part = locality.delete(',()/').squish.tr(' ', '-') + '-' + postcode.strip
        # prefix of listing combination that includes locality_check and post code, to effectively parse through listings_data
        url_start + primary_key + '/' + final_part.downcase + '?view=isLetting'
        # suffix of listing combination that includes url info and primary key to sort/organize listings_data
      end

      def self.address(listing_array)
        address = ''
        # empty string that will allow address info to be pushed into parsable format for listing scraping
        address_hash = listing_array["Common.ContactGroup"]["Common.Address"]
        address += address_hash["Common.Line1"]
        address += (', ' + address_hash["Common.Line2"]) if address_hash["Common.Line2"].present?
        address += ', ' + address_hash["Common.Locallity"] + " "
        address += address_hash["Common.PostCode"]
        address
      end
    end
  end
end