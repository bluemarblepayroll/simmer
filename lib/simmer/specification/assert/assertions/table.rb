# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'bad_table_assertion'

module Simmer
  class Specification
    class Assert
      class Assertions
        class Table
          acts_as_hashable

          attr_reader :name, :record_set

          def initialize(name:, records: [])
            @name       = name.to_s
            @record_set = Util::RecordSet.new(records)

            freeze
          end

          def assert(database, _output)
            actual_records      = database.records(name, keys)
            actual_record_set   = Util::RecordSet.new(actual_records)

            return nil if actual_record_set == record_set

            BadTableAssertion.new(name, record_set, actual_record_set)
          end

          private

          def keys
            record_set.keys
          end
        end
      end
    end
  end
end
