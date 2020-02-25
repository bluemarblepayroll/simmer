# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'db_client'
require_relative 'fixture_set'
require_relative 'mock_pdi_client'
require_relative 'pdi_client'
require_relative 'runner'
require_relative 's3_client'
require_relative 'suite/result'
require_relative 'yaml_directory'

module Simmer
  class Suite
    class << self
      def from_file(path: File.join('config', 'simmer.yaml'), out: $stdout)
        contents = File.read(path)
        config   = YAML.safe_load(contents)

        new(config: config, out: out)
      end
    end

    # Configuration Keys
    DB_KEY           = 'db'
    MOCK_KEY         = 'mock'
    MOCK_ERR_KEY     = 'mock_err'
    PDI_KEY          = 'pdi'
    RESULTS_PATH_KEY = 'suite.results_path'
    S3_KEY           = 's3'
    SPEC_PATH_KEY    = 'suite.spec_path'

    # Paths
    FILES            = 'files'
    FIXTURES         = 'fixtures'
    TESTS            = 'tests'

    attr_reader :config, :out, :runner

    def initialize(config: {}, out: $stdout)
      @config   = config || {}
      @resolver = Objectable.resolver
      @out      = out
      @runner   = make_runner

      freeze
    end

    def run(path = '')
      runner_results = run_all_specs(path)

      Result.new(runner_results).tap do |result|
        if result.pass?
          out.puts('Suite ended successfully')
        else
          out.puts('Suite ended but was not successful')
        end

        results_path = File.expand_path(get(RESULTS_PATH_KEY))
        result.write!(results_path)

        out.puts("Results can be viewed at #{results_path}")
      end
    end

    private

    attr_reader :resolver

    def run_all_specs(path)
      path = path.to_s.empty? ? tests_path : path

      out.puts("Simmer suite started for: #{path}")

      files = resolve_spec_files(path)
      count = files.length

      out.puts("Running #{count} test(s)")
      print_line

      files.map.with_index(1) do |file, index|
        run_single_spec(file, index, count)
      end
    end

    def run_single_spec(path, index, count)
      specification = Specification.from_file(path)

      out.puts("Test #{index} of #{count}")

      runner.run(specification, config: config).tap do
        print_line
      end
    end

    def resolve_spec_files(path)
      if File.directory?(path)
        glob = File.join(path, '**', '*_spec.yaml')
        Dir[glob].to_a
      else
        Array(path)
      end
    end

    def print_line
      out.puts('-' * 55)
    end

    def make_runner
      Runner.new(
        db_client: db_client,
        out: out,
        pdi_client: pdi_client,
        s3_client: s3_client
      )
    end

    def db_client
      DbClient.new(get(DB_KEY), fixture_set)
    end

    def s3_client
      S3Client.new(get(S3_KEY))
    end

    def pdi_client
      if get(MOCK_KEY)
        MockPdiClient.new
      elsif get(MOCK_ERR_KEY)
        MockPdiClient.new(false)
      else
        PdiClient.new(get(PDI_KEY), files_path)
      end
    end

    def get(key)
      resolver.get(config, key)
    end

    def spec_path
      get(SPEC_PATH_KEY).to_s
    end

    def files_path
      File.join(spec_path, FILES)
    end

    def fixtures_path
      File.join(spec_path, FIXTURES)
    end

    def tests_path
      File.join(spec_path, TESTS)
    end

    def fixture_set
      fixtures_config = YamlDirectory.new(fixtures_path)

      FixtureSet.new(fixtures_config.read)
    end
  end
end
