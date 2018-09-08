require "./controller"

module Amber
  class StaticController < Controller
    # If static resource is not found then raise an exception
    def index
      raise Amber::Exceptions::RouteNotFound.new(request)
    end
  end
end
