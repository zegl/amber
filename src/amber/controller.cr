require "http"

require "./params"
require "./controller/params_validator"
require "./controller/filters"
require "./controller/csrf"
require "./controller/redirect"
require "./controller/render"
require "./controller/responders"
require "./controller/route_info"
require "./controller/i18n"

macro params(klass, key = nil)
  private class {{klass.id}}
    include ParamsValidator

    {{yield}}
  end

  def {{klass.id.downcase}}
    {{klass.id}}.new(context.params)
  end
end

module Amber
  class Controller
    include CSRF
    include Redirect
    include Render
    include Responders
    include RouteInfo
    include I18n

    property filters : Filters = Filters.new
    protected getter context : HTTP::Server::Context
    protected getter raw_params : Amber::Params

    delegate :logger, to: Amber.settings

    delegate :client_ip,
      :cookies,
      :delete?,
      :flash,
      :format,
      :get?,
      :halt!,
      :head?,
      :patch?,
      :port,
      :post?,
      :put?,
      :request,
      :requested_url,
      :response,
      :route,
      :session,
      :valve,
      :websocket?,
      to: context

    def initialize(@context : HTTP::Server::Context)
      @raw_params = context.params
    end

    macro before_action
      def before_filters : Nil
        filters.register :before do
          {{yield}}
        end
      end
    end

    macro after_action
      def after_filters : Nil
        filters.register :after do
          {{yield}}
        end
      end
    end

    # TODO: Find a way to make these protected again.
    def run_before_filter(action)
      if self.responds_to? :before_filters
        self.before_filters
        @filters.run(:before, :all)
        @filters.run(:before, action)
      end
    end

    def run_after_filter(action)
      if self.responds_to? :after_filters
        self.after_filters
        @filters.run(:after, action)
        @filters.run(:after, :all)
      end
    end
  end
end
