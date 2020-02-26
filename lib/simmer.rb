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

require_relative 'simmer/db_client'
require_relative 'simmer/fixture_set'
require_relative 'simmer/mock_pdi_client'
require_relative 'simmer/pdi_client'
require_relative 'simmer/runner'
require_relative 'simmer/s3_client'
require_relative 'simmer/session'
require_relative 'simmer/specification'

module Simmer
  class Suite
    # Configuration Keys
    DB_KEY           = 'db'
    MOCK_KEY         = 'mock'
    MOCK_ERR_KEY     = 'mock_err'
    PDI_KEY          = 'pdi'
    S3_KEY           = 's3'

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

      files.map { |file| Specification.from_file(file) }
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
        PdiClient.new(get(PDI_KEY), files_dir)
      end
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
  end

  DEFAULT_CONFIG_PATH = File.join('config', 'simmer.yaml')
  DEFAULT_RESULTS_DIR = 'results'
  DEFAULT_SPEC_DIR    = 'spec'

  class << self
    def run(
      path = '',
      out: $stdout,
      config_path: DEFAULT_CONFIG_PATH,
      results_dir: DEFAULT_RESULTS_DIR,
      spec_dir: DEFAULT_SPEC_DIR
    )
      config = read_yaml(config_path)

      suite = Suite.new(
        config: config,
        out: out,
        results_dir: results_dir,
        spec_dir: spec_dir
      )

      suite.run(path)
    end

    private

    def read_yaml(path)
      contents = File.read(path)

      YAML.safe_load(contents)
    end
  end
end
