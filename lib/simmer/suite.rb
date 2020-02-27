# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'configuration'
require_relative 'externals'
require_relative 'runner'
require_relative 'session'
require_relative 'specification'

# Entrypoint to the library
module Simmer
  class Suite
    DEFAULT_CONFIG_PATH = File.join('config', 'simmer.yaml')
    DEFAULT_RESULTS_DIR = 'results'
    DEFAULT_SPEC_DIR    = 'simmer'

    attr_reader :configuration, :session

    def initialize(
      out: $stdout,
      config_path: DEFAULT_CONFIG_PATH,
      results_dir: DEFAULT_RESULTS_DIR,
      spec_dir: DEFAULT_SPEC_DIR
    )
      @configuration = Configuration.new(
        config_path: config_path,
        results_dir: results_dir,
        spec_dir: spec_dir
      )

      runner = Runner.new(
        database: database,
        file_system: file_system,
        out: out,
        spoon_client: spoon_client
      )

      @session = Session.new(
        config: configuration.config,
        out: out,
        results_dir: results_dir,
        runner: runner
      )

      freeze
    end

    def run(path)
      session.run(specifications(path))
    end

    private

    def specifications(path)
      path = path.to_s.empty? ? configuration.tests_dir : path

      Util::YamlReader.new.all(path).map do |file, config|
        config = (config || {}).merge(path: file)
        Specification.make(config)
      end
    end

    def database
      Externals::MysqlDatabase.new(configuration.database_config, configuration.fixture_set)
    end

    def file_system
      Externals::AwsFileSystem.new(configuration.file_system_config, configuration.files_dir)
    end

    def spoon_client
      Externals::SpoonClient.new(configuration.spoon_client_config, configuration.files_dir)
    end
  end
end
