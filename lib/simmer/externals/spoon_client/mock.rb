# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module Simmer
  module Externals
    class SpoonClient
      class Mock
        attr_reader :pass

        def initialize(pass = true)
          @pass = pass

          freeze
        end

        def run(*)
          raise Pdi::Spoon::KitchenError, 'mocked' unless pass

          Pdi::Executor::Result.new(
            args: [],
            status: {
              code: 0,
              err: 'Some error output from PDI',
              out: 'Some output from PDI',
              pid: 123
            }
          )
        end
      end
    end
  end
end
