# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'judge/bad_output_assertion'
require_relative 'judge/bad_table_assertion'
require_relative 'judge/result'

module Simmer
  class Suite
    class Runner
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
            bad_assert =
              if assertion.is_a?(Specification::Assert::Assertions::Table)
                table_assert(assertion)
              elsif assertion.is_a?(Specification::Assert::Assertions::Output)
                output_assert(assertion, output)
              else
                raise ArgumentError, "cannot handle assertion: #{assertion.class.name}"
              end

            memo << bad_assert if bad_assert
          end

          Result.new(bad_assertions)
        end

        private

        def output_assert(assertion, output)
          value = assertion.value.to_s

          return nil if output.to_s.include?(value)

          BadOutputAssertion.new(value)
        end

        def table_assert(assertion)
          table_name          = assertion.name
          fields              = assertion.keys
          actual_records      = database.records(table_name, fields)
          actual_record_set   = Util::RecordSet.new(actual_records)
          expected_record_set = assertion.record_set

          return nil if actual_record_set == expected_record_set

          BadTableAssertion.new(
            table_name,
            expected_record_set,
            actual_record_set
          )
        end
      end
    end
  end
end
