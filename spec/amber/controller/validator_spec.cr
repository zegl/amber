require "http"
require "../../../spec_helper"

class FakeController
  macro params(klass, key = nil)
    private class {{klass}}
      include Validator
      {{yield}}
    end

    def initialize
     @params = HTTP::Params.parse("name=John Doe&age=21&email=eliasjpr@gmail.com&alive=true").to_h
      @{{klass.stringify.id.downcase}} = {{klass}}.new(@params)
    end
  end

  params User do
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
      controller = FakeController.new

      controller.index.should be_true
    end
  end
end
