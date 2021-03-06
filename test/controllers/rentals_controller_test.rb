require "test_helper"

describe RentalsController do

  CHECKOUT_ATTRS = ["available_inventory", "customer_id", "due_date", "video_id", "videos_checked_out_count"].sort
  CHECKIN_ATTR = ["customer_id", "video_id", "videos_checked_out_count", "available_inventory"].sort

  describe "check out" do
    let(:check_out_data) {
      {
        customer_id: customers(:customer_one).id,
        video_id: videos(:fake_vid).id,
      }
    }

    it "creates a rental checkout" do
      customer_before_video_count = customers(:customer_one).videos_checked_out_count
      videos_before_available_count = videos(:fake_vid).available_inventory

      expect {
        post check_out_path, params: check_out_data
      }.must_differ "Rental.count", 1

      customers(:customer_one).reload
      videos(:fake_vid).reload

      expect(customers(:customer_one).videos_checked_out_count).must_equal (customer_before_video_count + 1)
      expect(videos(:fake_vid).available_inventory).must_equal (videos_before_available_count - 1)

      must_respond_with :ok

      body = JSON.parse(response.body)
      expect(body).must_be_instance_of Hash
      expect(body.keys.sort).must_equal CHECKOUT_ATTRS
    end

    it "will respond with bad_request if the customer is not found" do 
      check_out_data[:customer_id] = nil

      expect {
        post check_out_path, params: check_out_data
      }.wont_change "Rental.count"

      must_respond_with :not_found 

      expect(response.header['Content-Type']).must_include 'json'
      body = JSON.parse(response.body)
      expect(body["errors"]).must_equal ["Not Found"]
    end

    it "will respond with bad_request if the video is not found" do 
      check_out_data[:video_id] = nil

      expect {
        post check_out_path, params: check_out_data
      }.wont_change "Rental.count"

      must_respond_with :not_found 

      expect(response.header['Content-Type']).must_include 'json'
      body = JSON.parse(response.body)
      expect(body["errors"]).must_equal ["Not Found"]
    end

    it "will respond with ok false if the video is not in stock" do 
      check_out_data[:video_id] = videos(:none_avail_vid).id

      expect {
        post check_out_path, params: check_out_data
      }.wont_change "Rental.count"

      must_respond_with :bad_request 

      expect(response.header['Content-Type']).must_include 'json'
      body = JSON.parse(response.body)
      expect(body["errors"]).must_equal ["Not Found"]
    end
  end

  describe "check in" do
    let(:check_in_data) {
      {
        customer_id: customers(:customer_one).id,
        video_id: videos(:fake_vid).id,
      }
    }

    it "Successfully checks in a rental" do 
      post check_out_path, params: check_in_data
      must_respond_with :ok

      customers(:customer_one).reload
      videos(:fake_vid).reload

      customer_before_video_count = customers(:customer_one).videos_checked_out_count
      videos_before_available_count = videos(:fake_vid).available_inventory

      expect{
        post check_in_path, params: check_in_data
      }.wont_change "Rental.count"

      customers(:customer_one).reload
      videos(:fake_vid).reload

      must_respond_with :ok

      expect(customers(:customer_one).videos_checked_out_count).must_equal (customer_before_video_count - 1)
      expect(videos(:fake_vid).available_inventory).must_equal (videos_before_available_count + 1)

      body = JSON.parse(response.body)
      expect(body).must_be_instance_of Hash
      expect(body.keys.sort).must_equal CHECKIN_ATTR
    end

    it "Will respond with not_found if customer is not found" do 
      check_in_data[:customer_id] = nil 

      expect {
        post check_in_path, params: check_in_data
      }.wont_change "Rental.count"

      must_respond_with :not_found

      expect(response.header['Content-Type']).must_include 'json'
      body = JSON.parse(response.body)
      expect(body["errors"]).must_equal ["Not Found"]
    end

    it "Will respond with not_found if video is not found" do
      check_in_data[:video_id] = nil 
      
      expect {
        post check_in_path, params: check_in_data
      }.wont_change "Rental.count"

      must_respond_with :not_found

      expect(response.header['Content-Type']).must_include 'json'
      body = JSON.parse(response.body)
      expect(body["errors"]).must_equal ["Not Found"]
    end
  end
end
