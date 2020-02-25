# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module Simmer
  class Specification
    class Assert
      class Assertions
        class Table
          acts_as_hashable

          attr_reader :name, :record_set

          def initialize(name:, records: [])
            @name       = name.to_s
            @record_set = RecordSet.new(records)

            freeze
          end

          def keys
            record_set.keys
          end
        end
      end
    end
  end
end
