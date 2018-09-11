module ParamsParsers
  alias Files = Hash(String, File)
  alias Parameters = Hash(String, String)

  module Multipart
    def self.parse(request : HTTP::Request) : Tuple(ParamsParsers::Parameters, Files)
      multipart_params = ParamsParsers::Parameters.new
      files = Files.new

      HTTP::FormData.parse(request) do |upload|
        next unless upload
        filename = upload.filename
        if filename.is_a?(String) && !filename.empty?
          files[upload.name] = File.new(upload: upload)
        else
          multipart_params[upload.name] = upload.body.gets_to_end
        end
      end
      {multipart_params, files}
    end
  end
end
