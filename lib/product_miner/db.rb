# frozen_string_literal: true

require "active_record"
require "yaml"

module ProductMiner
  class DB
    def self.connect!
      config = YAML.load_file("config/database.yml")[ENV.fetch("ENV", "development")]
      ActiveRecord::Base.establish_connection(config)
    end
  end
end
