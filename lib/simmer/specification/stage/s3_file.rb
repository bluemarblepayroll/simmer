# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module Simmer
  class Specification
    class Stage
      class S3File
        acts_as_hashable

        attr_reader :key, :path

        def initialize(key:, path:)
          raise ArgumentError, 'key is required'  if key.to_s.empty?
          raise ArgumentError, 'path is required' if path.to_s.empty?

          @key  = key.to_s
          @path = path.to_s

          freeze
        end
      end
    end
  end
end
