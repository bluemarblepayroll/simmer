# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'resolver'

module Simmer
  module Util
    # Text template renderer.  It knows how to take a string and object as an input and
    # output a compiled string.
    class Evaluator
      def initialize
        @resolver = Objectable.resolver

        freeze
      end

      def evaluate(string, input = {})
        Stringento.evaluate(string, input, resolver: Resolver.new)
      end

      private

      attr_reader :resolver
    end
  end
end
