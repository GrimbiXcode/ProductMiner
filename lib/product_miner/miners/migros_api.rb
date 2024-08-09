# frozen_string_literal: true

require "rest-client"
require "json"

# A miner for Migros API to fetch product details
class MigrosApi
  def initialize
    @user_id = nil
    @leshopch_header = ""
    @auth_state = :UNAUTHORIZED
    @migros_url = "https://www.migros.ch"
  end

  def migros_headers(id)
    {
      Leshopch: @leshopch_header,
      params: {
        storeType: "OFFLINE",
        warehouseId: 2,
        region: "national",
        migrosIds: id
      }
    }
  end

  def authorize
    response = RestClient.get "#{@migros_url}/authentication/public/v1/api/guest?authorizationNotRequired=true"
    puts response.headers
    @leshopch_header = response.headers[:leshopch] || ""

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
    response = RestClient.get "#{@migros_url}/product-display/public/v2/product-detail", migros_headers(id)
    puts "Payload: \n"
    JSON.parse(response.body)
  end
end
