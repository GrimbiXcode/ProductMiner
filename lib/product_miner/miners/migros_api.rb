# frozen_string_literal: true

require "rest-client"
require "json"
require "logger"

# A miner for Migros API to fetch product details
class MigrosApi
  def initialize(logger = Logger.new($stdout))
    @user_id = nil
    @leshopch_header = ""
    @auth_state = :UNAUTHORIZED
    @migros_url = "https://www.migros.ch"
    @logger = logger
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
    @logger.debug("Authorization response headers: #{response.headers}")
    @leshopch_header = response.headers[:leshopch] || ""

    if @leshopch_header == ""
      # raise error
      @auth_state = :UNAUTHORIZED
      raise "No authorization header was found in the response"
    end

    @auth_state = :AUTHORIZED
    @logger.info("Found leshopch header: #{@leshopch_header}")
  end

  def read_product_details(id)
    authorize if @auth_state == :UNAUTHORIZED
    response = RestClient.get "#{@migros_url}/product-display/public/v2/product-detail", migros_headers(id)
    @logger.debug("Product payload received")
    JSON.parse(response.body)
  end
end
