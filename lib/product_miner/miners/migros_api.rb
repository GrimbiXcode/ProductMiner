# frozen_string_literal: true

require "httpx"

# A miner for Migros API to fetch product details
class MigrosApi
  def initialize
    @user_id = nil
    @leshopch_header = ""
    @auth_state = :UNAUTHORIZED
    @migros_api = HTTPX.with(origin: "https://www.migros.ch")
  end

  def migros_headers
    { headers: { Leshopch: @leshopch_header } }
  end

  def get_query(id)
    "?storeType=OFFLINE&warehouseId=2&region=national&migrosIds=#{id}"
  end

  def authorize
    response = @migros_api.get("/authentication/public/v1/api/guest?authorizationNotRequired=true")
    @leshopch_header = response.headers["Leshopch"] || ""

    if @leshopch_header == ""
      # raise error
      @auth_state = :UNAUTHORIZED
      raise "No authorization header was found in the response"
    end

    @auth_state = :AUTHORIZED
    puts "Found leshopch header: #{@leshopch_header}"
  end

  def read_product_details(id)
    authorize if @auth_state == :UNAUTHORIZED
    response = @migros_api.with(headers: { "Leshopch" => @leshopch_header })
                          .get("https://www.migros.ch/product-display/public/v2/product-detail#{get_query(id)}")
    puts "Payload: \n"
    puts response.json
  end
end
