# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'pdi_client/result'

module Simmer
  class MockPdiClient
    attr_reader :pass

    def initialize(pass = true)
      @pass = pass

      freeze
    end

    def run(specification, config = {})
      PdiClient::Result.new(
        message: message,
        execution_result: execution_result(specification, config),
        time_in_seconds: 123
      )
    end

    private

    def message
      pass ? 'Mocked success' : 'Mocked error'
    end

    def code
      pass ? 0 : 1
    end

    def execution_result(specification, config)
      files_path = 'files'
      script = 'something.sh'

      compiled_params = specification.act.compiled_params(files_path, config)

      args = compiled_params.each_with_object([script]) do |(k, v), memo|
        memo << "#{k}=#{v}"
      end

      Pdi::Executor::Result.new(
        args: args,
        status: {
          code: code,
          err: 'Some error output from PDI',
          out: 'Some output from PDI',
          pid: 123
        }
      )
    end
  end
end
