# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module Simmer
  class Suite
    class Specification
      class Assert
        class Assertions
          class Output
            acts_as_hashable

            attr_reader :value

            def initialize(value:)
              @value = value.to_s

              freeze
            end
          end
        end
      end
    end
  end
end
