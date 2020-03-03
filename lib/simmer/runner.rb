# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'judge'
require_relative 'runner/result'

module Simmer
  # Runs a single specification.
  class Runner
    def initialize(database:, file_system:, out:, spoon_client:)
      @database     = database
      @file_system  = file_system
      @judge        = Judge.new(database)
      @out          = out
      @spoon_client = spoon_client

      freeze
    end

    def run(specification, config: {}, id: SecureRandom.uuid)
      print("Name: #{specification.name}")
      print("Path: #{specification.path}")

      clean_db
      seed_db(specification)
      clean_file_system
      seed_file_system(specification)

      spoon_client_result = execute_spoon(specification, config)
      judge_result        = assert(specification, spoon_client_result)

      Result.new(id, judge_result, specification, spoon_client_result).tap do |result|
        msg = result.pass? ? 'PASS' : 'FAIL'
        print_waiting('Done', 'Final verdict')
        print(msg)
      end
    end

    private

    attr_reader :database, :file_system, :judge, :out, :spoon_client

    def clean_db
      print_waiting('Stage', 'Cleaning database')
      count = database.clean!
      print("#{count} table(s) emptied")

      count
    end

    def seed_db(specification)
      print_waiting('Stage', 'Seeding database')
      count = database.seed!(specification)
      print("#{count} record(s) inserted")

      count
    end

    def clean_file_system
      print_waiting('Stage', 'Cleaning File System')
      count = file_system.clean!
      print("#{count} file(s) deleted")

      count
    end

    def seed_file_system(specification)
      print_waiting('Stage', 'Seeding File System')
      count = file_system.write!(specification)
      print("#{count} file(s) uploaded")

      count
    end

    def execute_spoon(specification, config)
      print_waiting('Act', 'Executing Spoon')
      spoon_client_result = spoon_client.run(specification, config)
      msg = spoon_client_result.pass? ? 'Pass' : 'Fail'
      print(msg)

      spoon_client_result
    end

    def assert(specification, spoon_client_result)
      print_waiting('Assert', 'Checking results')

      if spoon_client_result.fail?
        print('Skipped')
        return nil
      end

      output       = spoon_client_result.execution_result.out
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
