# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module Simmer
  module Util
    class Resolver
      attr_reader :objectable_resolver

      def initialize
        @objectable_resolver = Objectable.resolver

        freeze
      end

      def resolve(value, input)
        objectable_resolver.get(input, value)
      end
    end
  end
end
