require "test_helper"

class SellingUnitTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    selling_unit = selling_units(:one)
    assert selling_unit.valid?
  end

  test "should belong to a product" do
    selling_unit = selling_units(:one)
    assert_respond_to selling_unit, :product
    assert_instance_of Product, selling_unit.product
  end

  test "should belong to a vendor" do
    selling_unit = selling_units(:one)
    assert_respond_to selling_unit, :vendor
    assert_instance_of Vendor, selling_unit.vendor
  end

  test "should belong to a manufacturer" do
    selling_unit = selling_units(:one)
    assert_respond_to selling_unit, :manufacturer
    assert_instance_of Manufacturer, selling_unit.manufacturer
  end

  test "should belong to a unit" do
    selling_unit = selling_units(:one)
    assert_respond_to selling_unit, :unit
    assert_instance_of Unit, selling_unit.unit
  end

  test "should belong to a currency" do
    selling_unit = selling_units(:one)
    assert_respond_to selling_unit, :currency
    assert_instance_of Currency, selling_unit.currency
  end

  test "should require a product" do
    selling_unit = SellingUnit.new(
      vendor: vendors(:one),
      manufacturer: manufacturers(:one),
      unit: units(:one),
      currency: currencies(:one),
      amount: 9.99
    )
    assert_not selling_unit.valid?
    assert_includes selling_unit.errors[:product], "must exist"
  end

  test "should require a vendor" do
    selling_unit = SellingUnit.new(
      product: products(:one),
      manufacturer: manufacturers(:one),
      unit: units(:one),
      currency: currencies(:one),
      amount: 9.99
    )
    assert_not selling_unit.valid?
    assert_includes selling_unit.errors[:vendor], "must exist"
  end

  test "should require a manufacturer" do
    selling_unit = SellingUnit.new(
      product: products(:one),
      vendor: vendors(:one),
      unit: units(:one),
      currency: currencies(:one),
      amount: 9.99
    )
    assert_not selling_unit.valid?
    assert_includes selling_unit.errors[:manufacturer], "must exist"
  end

  test "should require a unit" do
    selling_unit = SellingUnit.new(
      product: products(:one),
      vendor: vendors(:one),
      manufacturer: manufacturers(:one),
      currency: currencies(:one),
      amount: 9.99
    )
    assert_not selling_unit.valid?
    assert_includes selling_unit.errors[:unit], "must exist"
  end

  test "should require a currency" do
    selling_unit = SellingUnit.new(
      product: products(:one),
      vendor: vendors(:one),
      manufacturer: manufacturers(:one),
      unit: units(:one),
      amount: 9.99
    )
    assert_not selling_unit.valid?
    assert_includes selling_unit.errors[:currency], "must exist"
  end

  test "should have an amount" do
    selling_unit = selling_units(:one)
    assert_not_nil selling_unit.amount
    assert_equal 9.99, selling_unit.amount
  end
end
