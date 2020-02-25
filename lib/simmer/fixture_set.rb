# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'fixture_set/fixture'

module Simmer
  class FixtureSet
    def initialize(config = {})
      @fixtures_by_name = config.each_with_object({}) do |(name, fixture_config), memo|
        memo[name.to_s] = Fixture.make((fixture_config || {}).merge('name' => name))
      end

      freeze
    end

    def get!(name)
      key = name.to_s

      raise ArgumentError, "fixture not found: #{name}" unless fixtures_by_name.key?(key)

      fixtures_by_name[key]
    end

    def all
      fixtures_by_name.values
    end

    private

    attr_reader :fixtures_by_name
  end
end
