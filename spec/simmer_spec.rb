# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'spec_helper'
require './spec/mocks/out'

describe Simmer do
  let(:path)        { File.join('spec', 'fixtures', 'specifications', 'load_noc_list.yaml') }
  let(:config_path) { File.join('spec', 'config', 'simmer.yaml') }
  let(:simmer_dir)  { File.join('spec', 'simmer_spec') }
  let(:out)         { Out.new }

  context 'when pdi passes and table assertion fails' do
    specify 'judge determines it does not pass' do
      results = described_class.run(
        path,
        config_path: config_path,
        out: out,
        simmer_dir: simmer_dir
      )

      expect(results.pass?).to be false
    end
  end
end
