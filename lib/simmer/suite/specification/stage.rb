# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'stage/s3_file'

module Simmer
  class Suite
    class Specification
      class Stage
        acts_as_hashable

        attr_reader :fixtures, :s3_files

        def initialize(fixtures: [], s3_files: [])
          @fixtures = Array(fixtures).map(&:to_s)
          @s3_files = S3File.array(s3_files)

          freeze
        end
      end
    end
  end
end
