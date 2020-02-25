# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module Simmer
  class Suite
    class Result
      attr_reader :runner_results

      def initialize(runner_results = [])
        @runner_results = Array(runner_results)

        freeze
      end

      def pass?
        !fail?
      end

      def fail?
        runner_results.any?(&:fail?)
      end

      def write!(path)
        FileUtils.mkdir_p(path)

        data_path = File.join(path, 'data.yaml')
        pdi_out = File.join(path, 'pdi_out.txt')
        pdi_err = File.join(path, 'pdi_err.txt')

        IO.write(data_path, to_h.to_yaml)

        pdi_out_file = File.open(pdi_out, 'w')
        pdi_err_file = File.open(pdi_err, 'w')

        write_part(runner_results, pdi_out_file, pdi_err_file)

        pdi_out_file.close
        pdi_err_file.close

        self
      end

      def to_h
        {
          'pass' => pass?,
          'runner_results' => runner_results.map(&:to_h)
        }
      end

      private

      def write_part(runner_results, pdi_out_file, pdi_err_file)
        runner_results.each do |runner_result|
          name         = runner_result.name
          runner_id    = runner_result.id
          out_contents = runner_result.pdi_client_result.execution_result.out
          err_contents = runner_result.pdi_client_result.execution_result.err

          write_block(pdi_out_file, name, runner_id, out_contents)
          write_block(pdi_err_file, name, runner_id, err_contents)
        end

        nil
      end

      def write_block(file, name, runner_id, contents)
        hyphens = '-' * 80

        file.write("Name: #{name}\n")
        file.write("Runner ID: #{runner_id}\n")
        file.write("#{hyphens}\n")
        file.write("#{contents}\n")
        file.write("#{hyphens}\n")
        file.write("\n")

        nil
      end
    end
  end
end
