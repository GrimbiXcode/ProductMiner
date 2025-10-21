require "test_helper"

class ManufacturerTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    manufacturer = manufacturers(:one)
    assert manufacturer.valid?
  end

  test "should belong to a country" do
    manufacturer = manufacturers(:one)
    assert_respond_to manufacturer, :country
    assert_instance_of Country, manufacturer.country
  end

  test "should require a country" do
    manufacturer = Manufacturer.new(name: "Test Manufacturer", location: "Test Location")
    assert_not manufacturer.valid?
    assert_includes manufacturer.errors[:country], "must exist"
  end

  test "should have a name" do
    manufacturer = manufacturers(:one)
    assert_not_nil manufacturer.name
  end

  test "should have a location" do
    manufacturer = manufacturers(:one)
    assert_not_nil manufacturer.location
  end
end
