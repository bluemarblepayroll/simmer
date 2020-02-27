# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'db_client'
require_relative 'fixture_set'
require_relative 'pdi_client'
require_relative 'runner'
require_relative 's3_client'
require_relative 'session'
require_relative 'specification'
require_relative 'spoon_mock'

module Simmer
  class Suite
    # Configuration Keys
    BUCKET_KEY        = 's3.bucket'
    DB_KEY            = 'db'
    MOCK_KEY          = 'mock'
    MOCK_ERR_KEY      = 'mock_err'
    PDI_KEY           = 'pdi'
    S3_ENCRYPTION_KEY = 's3.encryption'
    S3_KEY            = 's3'

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

    def mysql2_client
      config = (get(DB_KEY) || {}).symbolize_keys

      Mysql2::Client.new(config)
    end

    def db_client
      DbClient.new(mysql2_client, fixture_set)
    end

    def aws_s3_bucket
      config = (get(S3_KEY) || {}).symbolize_keys

      client = Aws::S3::Client.new(
        access_key_id: config[:access_key_id],
        secret_access_key: config[:secret_access_key],
        region: config[:region]
      )

      bucket = get(BUCKET_KEY).to_s

      Aws::S3::Bucket.new(name: bucket, client: client)
    end

    def s3_client
      S3Client.new(aws_s3_bucket, get(S3_ENCRYPTION_KEY))
    end

    def spoon
      if get(MOCK_KEY)
        SpoonMock.new
      elsif get(MOCK_ERR_KEY)
        SpoonMock.new(false)
      else
        config = (get(PDI_KEY) || {}).symbolize_keys
        Pdi::Spoon.new(config)
      end
    end

    def pdi_client
      PdiClient.new(files_dir, spoon)
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
end
