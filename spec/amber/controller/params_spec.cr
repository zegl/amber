require "http"
require "../../../spec_helper"

class FakeController < Amber::Controller
  params("User") do
    param email : String, size: (5..64), regex: /\w+@\w+\.\w{2,}/
    param name : String, size: (5..10)
    param age : Int32, gte: 18
    param alive : Bool, in: [true, false]
  end

  def index
    user.valid?
  end
end

module Amber
  describe Controller do
    it "works" do
      request = HTTP::Request.new("GET", "/?email=eliasjpr@gmail.com&name=elias&age=37&alive=true")
      request.headers.add("Referer", "")
      context = create_context(request)
      controller = FakeController.new(context)

      controller.index.should be_true
    end
  end
end
