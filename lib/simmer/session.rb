# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'session/result'

module Simmer
  class Session
    attr_reader :config, :out, :results_dir, :runner

    def initialize(config:, out:, results_dir:, runner:)
      @config      = config || {}
      @out         = out
      @resolver    = Objectable.resolver
      @results_dir = results_dir
      @runner      = runner

      freeze
    end

    def run(specifications)
      runner_results = run_all_specs(specifications)

      Result.new(runner_results).tap do |result|
        if result.pass?
          out.puts('Suite ended successfully')
        else
          out.puts('Suite ended but was not successful')
        end

        result.write!(results_dir)

        out.puts("Results can be viewed at #{results_dir}")
      end
    end

    private

    attr_reader :resolver

    def run_all_specs(specifications)
      out.puts('Simmer suite started')

      count = specifications.length

      out.puts("Running #{count} specification(s)")
      print_line

      specifications.map.with_index(1) do |specification, index|
        run_single_spec(specification, index, count)
      end
    end

    def run_single_spec(specification, index, count)
      out.puts("Test #{index} of #{count}")

      runner.run(specification, config: config).tap do
        print_line
      end
    end

    def print_line
      out.puts('-' * 60)
    end
  end
end
