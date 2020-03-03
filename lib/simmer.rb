# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# External libraries
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
require_relative 'simmer/database'
require_relative 'simmer/externals'
require_relative 'simmer/runner'
require_relative 'simmer/specification'
require_relative 'simmer/suite'

# The main entry-point API for the library.
module Simmer
  DEFAULT_CONFIG_PATH = File.join('config', 'simmer.yaml')
  DEFAULT_RESULTS_DIR = 'results'
  DEFAULT_SIMMER_DIR  = 'simmer'

  class << self
    def run(
      path,
      config_path: DEFAULT_CONFIG_PATH,
      out: $stdout,
      results_dir: DEFAULT_RESULTS_DIR,
      simmer_dir: DEFAULT_SIMMER_DIR
    )
      # Get configuration
      yaml_reader   = Util::YamlReader.new
      raw_config    = yaml_reader.smash(config_path)
      configuration = Configuration.new(raw_config, results_dir, simmer_dir)

      # Get fixtures
      raw_fixtures = yaml_reader.smash(configuration.fixtures_dir)
      fixtures     = Database::FixtureSet.new(raw_fixtures)

      # Get specifications to run
      specs = make_specifications(path, configuration.tests_dir)

      # Make main executable instances
      runner = make_runner(configuration, out, fixtures)
      suite  = Suite.new(
        config: configuration.config,
        out: out,
        results_dir: results_dir,
        runner: runner
      )

      suite.run(specs)
    end

    private

    def make_specifications(path, tests_dir)
      path = path.to_s.empty? ? tests_dir : path

      Util::YamlReader.new.read(path).map do |file|
        config = (file.data || {}).merge(path: file.path)

        Specification.make(config)
      end
    end

    def make_runner(configuration, out, fixtures)
      database     = make_mysql_database(configuration, fixtures)
      file_system  = make_aws_file_system(configuration)
      spoon_client = make_spoon_client(configuration)

      Runner.new(
        database: database,
        file_system: file_system,
        out: out,
        spoon_client: spoon_client
      )
    end

    def make_fixture_set(configuration)
      config = Util::YamlReader.new.smash(configuration.fixtures_dir)

      Database::FixtureSet.new(config)
    end

    def make_mysql_database(configuration, fixtures)
      Externals::MysqlDatabase.new(
        configuration.mysql_database_config,
        fixtures
      )
    end

    def make_aws_file_system(configuration)
      config = (configuration.aws_file_system_config || {}).symbolize_keys

      Externals::AwsFileSystem.new(
        make_aws_s3_client(config),
        config[:bucket],
        config[:encryption],
        configuration.files_dir
      )
    end

    def make_spoon_client(configuration)
      Externals::SpoonClient.new(
        configuration.spoon_client_config,
        configuration.files_dir
      )
    end

    def make_aws_s3_client(config)
      Aws::S3::Client.new(
        access_key_id: config[:access_key_id],
        secret_access_key: config[:secret_access_key],
        region: config[:region]
      )
    end
  end
end
