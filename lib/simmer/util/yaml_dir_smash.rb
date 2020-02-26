# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module Simmer
  module Util
    class YamlDirSmash
      EXTENSIONS = %w[yml yaml].freeze

      attr_reader :path

      def initialize(path)
        @path = path
      end

      def read
        @read ||= read_files.each_with_object({}) { |config, memo| memo.merge!(config) }
      end

      private

      def wildcard_name
        "*.{#{EXTENSIONS.join(',')}}"
      end

      def full_path
        File.join(path, '**', wildcard_name)
      end

      def read_files
        Dir[full_path].map do |filename|
          read_file(filename)
        end
      end

      # read, then YAML load in this specific order so, hopefully, it is easier to identify the
      # specific YAML file that causes issues.
      def read_file(filename)
        YAML.safe_load(File.read(filename)) || {}
      end
    end
  end
end
