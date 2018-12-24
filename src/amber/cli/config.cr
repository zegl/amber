module Amber::CLI
  def self.config
    if File.exists? AMBER_YML
      begin
        Config.from_yaml File.read(AMBER_YML)
      rescue ex : YAML::ParseException
        logger.error "Couldn't parse #{AMBER_YML} file", "Watcher", :red
        exit 1
      end
    else
      Config.new
    end
  end

  class Config
    SHARD_YML    = "shard.yml"
    DEFAULT_NAME = "[process_name]"

    # see defaults below
    alias WatchOptions = Hash(String, Hash(String, Array(String)))

    property database : String = "pg"
    property language : String = "slang"
    property model : String = "granite"
    property watch : WatchOptions

    def initialize
      @watch = default_watch_options
    end

    YAML.mapping(
      database: {type: String, default: "pg"},
      language: {type: String, default: "slang"},
      model: {type: String, default: "granite"},
      watch: {type: WatchOptions, default: default_watch_options}
    )

    def default_watch_options
      appname = self.class.get_name

      WatchOptions{
        "run" => Hash{
          "build_commands" => [
            "mkdir -p bin",
            "crystal build ./src/#{appname}.cr -o bin/#{appname}",
          ],
          "run_commands" => [
            "bin/#{appname}",
          ],
          "include" => [
            "./config/**/*.cr",
            "./src/**/*.cr",
            "./src/views/**/*.slang",
          ],
        },
        "npm" => Hash{
          "build_commands" => [
            "npm install --loglevel=error",
          ],
          "run_commands" => [
            "npm run watch",
          ],
        },
      }
    end

    def self.get_name
      if File.exists?(SHARD_YML) &&
         (yaml = YAML.parse(File.read SHARD_YML)) &&
         (name = yaml["name"]?)
        name.as_s
      else
        DEFAULT_NAME
      end
    end
  end
end
