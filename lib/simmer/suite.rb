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
  # The main object entrypoint that brings the entire codebase together.
  class Suite
    attr_reader :configuration, :session

    def initialize(config_path:, out:, results_dir:, simmer_dir:)
      @configuration = Configuration.new(
        config_path: config_path,
        results_dir: results_dir,
        simmer_dir: simmer_dir
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

      Util::YamlReader.new.read(path).map do |file|
        config = (file.data || {}).merge(path: file.path)

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
