# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'pdi_client/result'

module Simmer
  class PdiClient
    attr_reader :files_path,
                :spoon

    def initialize(config, files_path)
      config = (config || {}).symbolize_keys

      @spoon      = Pdi::Spoon.new(config)
      @files_path = files_path

      freeze
    end

    def run(specification, config = {})
      execution_result = nil
      time_in_seconds  = nil

      begin
        time_in_seconds = Benchmark.measure do
          execution_result = execute!(specification, config)
        end.real
      rescue Pdi::Spoon::PanError, Pdi::Spoon::KitchenError => e
        return Result.new(
          message: "PDI execution returned an error: #{e.class.name} (#{e.execution.code})",
          execution_result: e.execution,
          time_in_seconds: time_in_seconds
        )
      end

      Result.new(
        execution_result: execution_result,
        time_in_seconds: time_in_seconds
      )
    end

    private

    def execute!(specification, config)
      act = specification.act

      spoon.run(
        repository: act.repository,
        name: act.name,
        params: act.compiled_params(files_path, config),
        type: act.type
      )
    end
  end
end
