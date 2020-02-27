# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'externals'
require_relative 'fixture_set'
require_relative 'runner'
require_relative 'session'
require_relative 'specification'

module Simmer
  class Suite
    # Configuration Keys
    AWS_FILE_SYSTEM_KEY = :aws_file_system
    MYSQL_DATABASE_KEY  = :mysql_database
    SPOON_CLIENT_KEY    = :spoon_client

    # Paths
    FILES    = 'files'
    FIXTURES = 'fixtures'
    TESTS    = 'tests'

    attr_reader :config, :out, :results_dir, :spec_dir

    def initialize(config:, out:, results_dir:, spec_dir:)
      @config      = config || {}
      @out         = out
      @resolver    = Objectable.resolver
      @results_dir = results_dir
      @spec_dir    = spec_dir

      freeze
    end

    def run(path)
      specifications = resolve_specifications(path)

      session.run(specifications)
    end

    private

    attr_reader :resolver

    def resolve_specifications(path)
      path = path.to_s.empty? ? tests_dir : path

      files =
        if File.directory?(path)
          glob = File.join(path, '**', '*_spec.yaml')
          Dir[glob].to_a
        else
          Array(path)
        end

      files.map { |file| load_specification(file) }
    end

    def load_specification(path)
      contents = File.read(path)
      config   = YAML.safe_load(contents)

      Specification.make(config)
    end

    def session
      Session.new(
        config: config,
        out: out,
        results_dir: results_dir,
        runner: runner
      )
    end

    def runner
      Runner.new(
        database: database,
        file_system: file_system,
        out: out,
        spoon_client: spoon_client
      )
    end

    def get(key)
      resolver.get(config, key)
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
      fixtures_config = Util::YamlDirSmash.new(fixtures_dir)

      FixtureSet.new(fixtures_config.read)
    end

    def database
      Externals::MysqlDatabase.new(get(MYSQL_DATABASE_KEY), fixture_set)
    end

    def file_system
      Externals::AwsFileSystem.new(get(AWS_FILE_SYSTEM_KEY))
    end

    def spoon_client
      Externals::SpoonClient.new(get(SPOON_CLIENT_KEY), files_dir)
    end
  end
end
