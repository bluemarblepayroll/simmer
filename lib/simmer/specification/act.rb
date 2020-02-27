# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'act/params'

module Simmer
  class Specification
    class Act
      extend Forwardable
      acts_as_hashable

      module Type
        JOB            = :job
        TRANSFORMATION = :transformation
      end

      attr_reader :repository, :name, :type, :params

      def_delegator :params, :compile, :compiled_params

      def initialize(repository:, name:, type:, params: {})
        assert_presence(repository, 'repository')
        assert_presence(name, 'name')
        assert_presence(type, 'type')

        @repository = repository.to_s
        @name       = name.to_s
        @type       = Type.const_get(type.to_s.to_s.upcase.to_sym)
        @params     = Params.make(params)

        freeze
      end

      private

      def assert_presence(value, name)
        raise ArgumentError, "#{name} is required" if value.to_s.empty?
      end
    end
  end
end