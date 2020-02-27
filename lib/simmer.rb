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
require_relative 'simmer/suite'

module Simmer
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
