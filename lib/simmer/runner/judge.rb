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
  class Runner
    class Judge
      attr_reader :db_client

      def initialize(db_client)
        raise ArgumentError, 'db_client is required' unless db_client

        @db_client = db_client

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
        actual_records      = db_client.records(table_name, fields)
        actual_record_set   = RecordSet.new(actual_records)
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
