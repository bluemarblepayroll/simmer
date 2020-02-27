# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module Simmer
  module Util
    class YamlReader
      EXTENSIONS = %w[yml yaml].freeze

      private_constant :EXTENSIONS

      def smash(path)
        files = all(path).values

        files.each_with_object({}) do |config, memo|
          memo.merge!(config)
        end
      end

      def all(path)
        expand(path).map { |file| [file, read(file)] }.to_h
      end

      def read(path)
        contents = File.read(path)

        YAML.safe_load(contents) || {}
      end

      private

      def wildcard_name
        "*.{#{EXTENSIONS.join(',')}}"
      end

      def full_path(path)
        File.join(path, '**', wildcard_name)
      end

      def expand(path)
        path = File.expand_path(path.to_s)

        if File.directory?(path)
          glob = full_path(path)

          Dir[glob].to_a
        else
          Array(path)
        end
      end
    end
  end
end
