# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module Simmer
  module Util
    class Fixture
      acts_as_hashable

      attr_reader :fields,
                  :name,
                  :table

      def initialize(fields: {}, name:, table:)
        @fields = fields || {}
        @name   = name.to_s
        @table  = table.to_s
      end

      def to_s
        "#{name} (#{table}) #{fields}"
      end
    end
  end
end
