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
require_relative 'simmer/suite'

# The main entry-point API for the library.
module Simmer
  DEFAULT_CONFIG_PATH = File.join('config', 'simmer.yaml')
  DEFAULT_RESULTS_DIR = 'results'
  DEFAULT_SIMMER_DIR  = 'simmer'
  class << self
    def run(path)
      Suite.new(
        out: $stdout,
        config_path: DEFAULT_CONFIG_PATH,
        results_dir: DEFAULT_RESULTS_DIR,
        simmer_dir: DEFAULT_SIMMER_DIR
      ).run(path)
    end
  end
end
