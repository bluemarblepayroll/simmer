# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'configuration/fixture_set'

module Simmer
  class Suite
    class Configuration
      # Configuration Keys
      AWS_FILE_SYSTEM_KEY = :aws_file_system
      MYSQL_DATABASE_KEY  = :mysql_database
      SPOON_CLIENT_KEY    = :spoon_client

      # Paths
      FILES    = 'files'
      FIXTURES = 'fixtures'
      TESTS    = 'specs'

      private_constant :AWS_FILE_SYSTEM_KEY,
                       :MYSQL_DATABASE_KEY,
                       :SPOON_CLIENT_KEY,
                       :FILES,
                       :FIXTURES,
                       :TESTS

      attr_reader :config

      def initialize(
        config_path:,
        resolver: Objectable.resolver,
        results_dir:,
        spec_dir:,
        yaml_reader: Util::YamlReader.new
      )
        @config      = yaml_reader.read(config_path)
        @resolver    = resolver
        @results_dir = results_dir
        @spec_dir    = spec_dir
        @yaml_reader = yaml_reader

        freeze
      end

      def database_config
        get(MYSQL_DATABASE_KEY) || {}
      end

      def file_system_config
        get(AWS_FILE_SYSTEM_KEY) || {}
      end

      def spoon_client_config
        get(SPOON_CLIENT_KEY) || {}
      end

      def tests_dir
        File.join(spec_dir, TESTS)
      end

      def fixtures_dir
        File.join(spec_dir, FIXTURES)
      end

      def files_dir
        File.join(spec_dir, FILES)
      end

      def fixture_set
        config = yaml_reader.smash(fixtures_dir)

        FixtureSet.new(config)
      end

      private

      attr_reader :resolver,
                  :results_dir,
                  :spec_dir,
                  :yaml_reader

      def get(key)
        resolver.get(config, key)
      end
    end
  end
end