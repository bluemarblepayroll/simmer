# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'spec_helper'
require 'db_helper'

describe Simmer::Externals::SpoonClient do
  class Mock
    attr_reader :result

    def initialize(result)
      @result = result
    end

    def run(*)
      raise Pdi::Spoon::KitchenError, OpenStruct.new(code: 1) if result == 'KitchenError'
      raise Pdi::Spoon::PanError, OpenStruct.new(code: 1)     if result == 'PanError'

      Pdi::Executor::Result.new(result)
    end
  end

  let(:files_dir)            { File.join('spec', 'fixtures') }
  let(:specification_path)   { File.join('specifications', 'load_noc_list.yaml') }
  let(:specification_config) { yaml_fixture(specification_path).merge(path: specification_path) }
  let(:specification)        { Simmer::Specification.make(specification_config) }

  subject { described_class.new(files_dir, spoon) }

  context 'when PDI executes successfully' do
    let(:spoon) do
      Mock.new(
        args: [],
        status: {
          code: 0,
          err: 'Some error output from PDI',
          out: 'Some output from PDI',
          pid: 123
        }
      )
    end

    specify '#run is called with the right arguments' do
      expected_path = File.expand_path(File.join(files_dir, 'noc_list.csv'))

      args = {
        repository: 'top_secret',
        name: 'load_noc_list',
        params: {
          'input_file' => expected_path,
          'code' => 'The secret code is: '
        },
        type: 'transformation'
      }

      expect(spoon).to receive(:run).with(args)

      subject.run(specification, simmer_config)
    end
  end
end
