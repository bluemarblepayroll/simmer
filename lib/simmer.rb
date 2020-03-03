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
require_relative 'simmer/suite'
require_relative 'simmer/specification'

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
      configuration = Configuration.new(
        config_path: config_path,
        results_dir: results_dir,
        simmer_dir: simmer_dir
      )

      specs  = make_specifications(path, configuration.tests_dir)
      runner = make_runner(configuration, out)

      Suite.new(
        config: configuration.config,
        out: out,
        results_dir: results_dir,
        runner: runner
      ).run(specs)
    end

    def make_specifications(path, tests_dir)
      path = path.to_s.empty? ? tests_dir : path

      Util::YamlReader.new.read(path).map do |file|
        config = (file.data || {}).merge(path: file.path)

        Specification.make(config)
      end
    end

    def make_runner(configuration, out)
      database     = make_mysql_database(configuration)
      file_system  = make_aws_file_system(configuration)
      spoon_client = make_spoon_client(configuration)

      Runner.new(
        database: database,
        file_system: file_system,
        out: out,
        spoon_client: spoon_client
      )
    end

    def make_mysql_database(configuration)
      Externals::MysqlDatabase.new(
        configuration.database_config,
        configuration.fixture_set
      )
    end

    def make_aws_file_system(configuration)
      Externals::AwsFileSystem.new(
        configuration.file_system_config,
        configuration.files_dir
      )
    end

    def make_spoon_client(configuration)
      Externals::SpoonClient.new(
        configuration.spoon_client_config,
        configuration.files_dir
      )
    end
  end
end
