require "test_helper"

class SellingDatumTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    selling_datum = selling_data(:one)
    assert selling_datum.valid?
  end

  test "should belong to a selling unit" do
    selling_datum = selling_data(:one)
    assert_respond_to selling_datum, :selling_unit
    assert_instance_of SellingUnit, selling_datum.selling_unit
  end

  test "should require a selling unit" do
    selling_datum = SellingData.new(
      recorded_at: Time.current,
      value: 9.99
    )
    assert_not selling_datum.valid?
    assert_includes selling_datum.errors[:selling_unit], "must exist"
  end

  test "should have a recorded_at timestamp" do
    selling_datum = selling_data(:one)
    assert_not_nil selling_datum.recorded_at
    assert_instance_of ActiveSupport::TimeWithZone, selling_datum.recorded_at
  end

  test "should have a value" do
    selling_datum = selling_data(:one)
    assert_not_nil selling_datum.value
    assert_equal 9.99, selling_datum.value
  end

  test "should store price value as decimal" do
    selling_datum = selling_data(:one)
    assert_instance_of BigDecimal, selling_datum.value
  end
end
