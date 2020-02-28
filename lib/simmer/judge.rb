# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'judge/result'
require_relative 'specification'

module Simmer
  # Runs all assertions and reports back the results.
  class Judge
    attr_reader :database

    def initialize(database)
      raise ArgumentError, 'database is required' unless database

      @database = database

      freeze
    end

    def assert(specification, output)
      assertions = specification.assert.assertions

      bad_assertions = assertions.each_with_object([]) do |assertion, memo|
        bad_assert = assertion.assert(database, output)

        memo << bad_assert if bad_assert
      end

      Result.new(bad_assertions)
    end
  end
end
