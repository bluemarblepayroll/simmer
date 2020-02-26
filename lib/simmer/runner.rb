# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'runner/judge'
require_relative 'runner/result'

module Simmer
  class Runner
    attr_reader :db_client, :out, :pdi_client, :s3_client

    def initialize(db_client:, out:, pdi_client:, s3_client:)
      @db_client  = db_client
      @pdi_client = pdi_client
      @out        = out
      @s3_client  = s3_client
      @judge      = Judge.new(db_client)

      freeze
    end

    def run(specification, config: {})
      print(specification.name)

      clean_db
      seed_db(specification)
      clean_s3
      seed_s3(specification)

      pdi_client_result = execute_pdi(specification, config)
      judge_result      = assert(specification, pdi_client_result)

      Result.new(judge_result, specification.name, pdi_client_result).tap do |result|
        msg = result.pass? ? 'PASS' : 'FAIL'
        print_waiting('Done', 'Final verdict')
        print(msg)
      end
    end

    private

    attr_reader :judge

    def clean_db
      print_waiting('Stage', 'Cleaning database')
      count = db_client.clean!
      print("#{count} table(s) emptied")

      count
    end

    def seed_db(specification)
      print_waiting('Stage', 'Seeding database')
      count = db_client.seed!(specification)
      print("#{count} record(s) inserted")

      count
    end

    def clean_s3
      print_waiting('Stage', 'Cleaning S3')
      count = s3_client.clean!
      print("#{count} file(s) deleted")

      count
    end

    def seed_s3(specification)
      print_waiting('Stage', 'Seeding S3')
      count = s3_client.seed!(specification)
      print("#{count} file(s) uploaded")

      count
    end

    def execute_pdi(specification, config)
      print_waiting('Act', 'Executing PDI')
      pdi_client_result = pdi_client.run(specification, config)
      msg = pdi_client_result.pass? ? 'Pass' : 'Fail'
      print(msg)

      pdi_client_result
    end

    def assert(specification, pdi_client_result)
      print_waiting('Assert', 'Checking results')

      if pdi_client_result.fail?
        print('Skipped')
        return nil
      end

      output       = pdi_client_result.execution_result.out
      judge_result = judge.assert(specification, output)
      msg          = judge_result.pass? ? 'Pass' : 'Fail'

      print(msg)

      judge_result
    end

    def print(msg)
      out.puts(msg)
    end

    def print_waiting(stage, msg)
      max  = 25
      char = '.'
      msg  = "  > #{pad_right(stage, 6)} - #{pad_right(msg, max, char)}"

      out.print(msg)
    end

    def pad_right(msg, len, char = ' ')
      missing = len - msg.length

      "#{msg}#{char * missing}"
    end
  end
end
