# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'judge'

module Simmer
  class Runner
    class Result
      extend Forwardable

      attr_reader :id, :judge_result, :name, :pdi_client_result

      def_delegators :pdi_client_result, :time_in_seconds

      def initialize(id, judge_result, name, pdi_client_result)
        @id                = id
        @judge_result      = judge_result
        @name              = name.to_s
        @pdi_client_result = pdi_client_result

        freeze
      end

      def pass?
        pdi_client_result&.pass? && judge_result&.pass?
      end

      def fail?
        !pass?
      end

      def to_h
        {
          'name' => name,
          'id' => id,
          'time_in_seconds' => time_in_seconds,
          'pass' => pass?,
          'pdi_client_result' => pdi_client_result.to_h,
          'judge_result' => judge_result.to_h
        }
      end
    end
  end
end
