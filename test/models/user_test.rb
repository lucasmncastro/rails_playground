require 'test_helper'

class Foo
  def to_s
    "bar"
  end
end

class UserTest < ActiveSupport::TestCase
  setup do
    @date = Date.new(2017, 7, 14)
  end

  test "scope hopes receive a callable block" do
    error = assert_raise ArgumentError do
      class ::User 
        scope :test, where("updated_at >= 0")
      end
    end

    assert_equal "The scope body needs to be callable.", error.message
  end

  test "interpolation in ruby calls #to_s" do
    foo = Foo.new
    string = "#{foo}"

    assert_equal "bar", foo.to_s
  end

  test "Date#to_s cann't be suitable to the database" do
    Date::DATE_FORMATS[:default] = "%B %d, %Y"

    assert_raise ActiveRecord::StatementInvalid do
      User.where("updated_at > #{@date}").first
    end
  end

  # ActiveRecord uses DATE_FORMAT[:db] as you can see here:
  #
  # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/abstract/quoting.rb#L135
  test "prefer use query parameters" do
    assert_nothing_raised do
      User.where("updated_at > ?", @date).first
    end
  end

  test "the updated_at field is a TimeWithZone" do
    user = User.create!(name: "Jonh")
    assert_equal ActiveSupport::TimeWithZone, user.updated_at.class
  end

  test "rails stores updated_at (and created_at) in UTC (+00:00)" do
    user = User.create!(name: "Jonh")
    assert_equal "UTC", user.updated_at.zone
  end

  test "using Date as parameter we get the records from the beginning of day" do
    User.delete_all

    user1 = User.create!(name: "Luke", updated_at: "2017-07-11 00:00:00")
    user2 = User.create!(name: "Jonh", updated_at: "2017-07-12 00:00:00")
    user3 = User.create!(name: "Paul", updated_at: "2017-07-12 00:00:01")
    user4 = User.create!(name: "Mary", updated_at: "2017-07-13 00:00:00")

    expected = [user2, user3, user4]
    found    = User.where("updated_at >= ?", Date.new(2017, 7, 12)).to_a

    assert_equal(expected, found)
  end

  test "using Time as parameter we get the records from that time" do
    User.delete_all

    user1 = User.create!(name: "Luke", updated_at: "2017-07-11 00:00:00")
    user2 = User.create!(name: "Jonh", updated_at: "2017-07-12 00:00:00")
    user3 = User.create!(name: "Paul", updated_at: "2017-07-12 00:00:01")
    user4 = User.create!(name: "Mary", updated_at: "2017-07-13 00:00:00")

    expected = [user3, user4]
    found    = User.where("updated_at >= ?", Time.utc(2017, 7, 12, 0, 0, 1)).to_a

    assert_equal(expected, found)
  end

  test "using DateTime as parameter we also get the records from that time" do
    User.delete_all

    user1 = User.create!(name: "Luke", updated_at: "2017-07-11 00:00:00")
    user2 = User.create!(name: "Jonh", updated_at: "2017-07-12 00:00:00")
    user3 = User.create!(name: "Paul", updated_at: "2017-07-12 00:00:01")
    user4 = User.create!(name: "Mary", updated_at: "2017-07-13 00:00:00")

    expected = [user3, user4]
    found    = User.where("updated_at >= ?", DateTime.new(2017, 7, 12, 0, 0, 1)).to_a

    assert_equal(expected, found)
  end

  test "recently_updated should get the users updated 2 days ago from now" do
    User.delete_all

    two_days_ago = Time.now - 2.days

    user1 = User.create!(name: "Luke", updated_at: two_days_ago - 1.minute)
    user2 = User.create!(name: "Jonh", updated_at: two_days_ago + 1.minute)
    user3 = User.create!(name: "Paul", updated_at: Time.now)

    expected = [user2, user3]

    assert_equal(expected, User.recently_updated.to_a)
  end
end
