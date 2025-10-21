require "test_helper"

class VendorTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    vendor = vendors(:one)
    assert vendor.valid?
  end

  test "should belong to a country" do
    vendor = vendors(:one)
    assert_respond_to vendor, :country
    assert_instance_of Country, vendor.country
  end

  test "should require a country" do
    vendor = Vendor.new(name: "Test Vendor", location: "Test Location")
    assert_not vendor.valid?
    assert_includes vendor.errors[:country], "must exist"
  end

  test "should have a name" do
    vendor = vendors(:one)
    assert_not_nil vendor.name
  end

  test "should have a location" do
    vendor = vendors(:one)
    assert_not_nil vendor.location
  end
end
