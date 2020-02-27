# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'acts_as_hashable'
require 'aws-sdk-s3'
require 'benchmark'
require 'bigdecimal'
require 'fileutils'
require 'forwardable'
require 'mysql2'
require 'objectable'
require 'pdi'
require 'securerandom'
require 'set'
require 'stringento'
require 'yaml'

# Monkey-patching core libaries
require_relative 'simmer/core_ext/hash'
Hash.include Simmer::CoreExt::Hash

# Load up general use-case utils for entire library
require_relative 'simmer/util'

# Core code
require_relative 'simmer/configuration'
require_relative 'simmer/externals'
require_relative 'simmer/runner'
require_relative 'simmer/specification'
require_relative 'simmer/suite'

# Entrypoint to the library
module Simmer
  class Glue
    attr_reader :configuration, :suite

    def initialize(
      out:,
      config_path:,
      results_dir:,
      spec_dir:
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

      @suite = Suite.new(
        config: configuration.config,
        out: out,
        results_dir: results_dir,
        runner: runner
      )

      freeze
    end

    def run(path)
      suite.run(specifications(path))
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

  DEFAULT_CONFIG_PATH = File.join('config', 'simmer.yaml')
  DEFAULT_RESULTS_DIR = 'results'
  DEFAULT_SPEC_DIR    = 'simmer'

  class << self
    def run(
      path = '',
      out: $stdout,
      config_path: DEFAULT_CONFIG_PATH,
      results_dir: DEFAULT_RESULTS_DIR,
      spec_dir: DEFAULT_SPEC_DIR
    )
      Glue.new(
        out: out,
        config_path: config_path,
        results_dir: results_dir,
        spec_dir: spec_dir
      ).run(path)
    end
  end
end
