require "colorize"

module Amber
  module Exceptions
    class Base < Exception
      getter status_code : Int32 = 500

      def set_response(response)
        response.headers["Content-Type"] = "text/plain"
        response.print message
        response.status_code = status_code
      end
    end

    class Environment < Exception
      def initialize(path, environment)
        super("Environment file not found for #{path}#{environment}")
      end
    end

    # NOTE: Any exceptions which aren't part of and http request cycle shouldn't inherit from Base.
    class EncryptionKeyMissing < Exception
      def initialize(file_path, encrypt_env)
        super(%(Encryption key not found. Please set it via '#{file_path}' or 'ENV[#{encrypt_env}]'.\n\n).colorize(:yellow).to_s)
      end
    end

    # Raised when storing more than 4K of session data.
    class CookieOverflow < Base
    end

    class InvalidSignature < Base
    end

    class InvalidMessage < Base
    end

    class DuplicateRouteError < Base
      def initialize(route : Route)
        super("Route: #{route.verb} #{route.resource} is duplicated.")
      end
    end

    class RouteNotFound < Base
      def initialize(request)
        @status_code = 404
        super("The request was not found. #{request.method} - #{request.path}")
      end
    end

    class Forbidden < Base
      def initialize(message : String?)
        @status_code = 403
        super(message || "Action is Forbidden.")
      end
    end
  end
end
