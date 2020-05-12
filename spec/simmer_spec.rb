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
  let(:src_config_path) { File.join('spec', 'config', 'simmer.yaml') }
  let(:config)          { yaml_read(src_config_path) }

  def stage_simmer_config(spoon_dir, args, timeout_in_seconds = nil)
    dest_config_dir  = File.join('tmp')
    dest_config_path = File.join(dest_config_dir, 'simmer.yaml')

    FileUtils.rm(dest_config_path) if File.exist?(dest_config_path)
    FileUtils.mkdir_p(dest_config_dir)

    timeout = timeout_in_seconds || config.dig('spoon_client', 'timeout_in_seconds')

    new_config = config.merge(
      'spoon_client' => {
        'dir' => spoon_dir,
        'args' => args,
        'timeout_in_seconds' => timeout
      }
    )

    IO.write(dest_config_path, new_config.to_yaml)

    dest_config_path
  end

  context 'when externally mocking pdi and using local file system' do
    let(:spec_path)   { File.join('spec', 'fixtures', 'specifications', 'load_noc_list.yaml') }
    let(:simmer_dir)  { File.join('spec', 'simmer_spec') }
    let(:out)         { Out.new }
    let(:config_path) { stage_simmer_config(spoon_path, args) }

    context 'when pdi does not do anything but does not fail' do
      let(:spoon_path)  { File.join('spec', 'mocks', 'spoon') }
      let(:args)        { 0 }

      specify 'judge determines it does not pass' do
        results = described_class.run(
          spec_path,
          config_path: config_path,
          out: out,
          simmer_dir: simmer_dir
        )

        expect(results.pass?).to be false
      end
    end

    context 'when pdi fails' do
      let(:spoon_path)  { File.join('spec', 'mocks', 'spoon') }
      let(:args)        { 1 }

      specify 'judge determines it does not pass' do
        results = described_class.run(
          spec_path,
          config_path: config_path,
          out: out,
          simmer_dir: simmer_dir
        )

        expect(results.pass?).to be false
      end
    end

    context 'when pdi acts correctly' do
      let(:spoon_path)  { File.join('spec', 'mocks', 'load_noc_list') }
      let(:args)        { '' }

      specify 'judge determines it to pass' do
        results = described_class.run(
          spec_path,
          config_path: config_path,
          out: out,
          simmer_dir: simmer_dir
        )

        expect(results.pass?).to be true
      end
    end

    context 'when pdi acts correctly but judge fails on output assert' do
      let(:spoon_path)  { File.join('spec', 'mocks', 'load_noc_list_bad_output') }
      let(:args)        { '' }

      specify 'judge determines it to pass' do
        results = described_class.run(
          spec_path,
          config_path: config_path,
          out: out,
          simmer_dir: simmer_dir
        )

        expect(results.pass?).to be false
      end
    end

    context 'when pdi times out' do
      let(:spoon_path)  { File.join('spec', 'mocks', 'spoon') }
      let(:args)        { [0, 10] }
      let(:config_path) { stage_simmer_config(spoon_path, args, 1) }

      it 'fails' do
        results = described_class.run(
          spec_path,
          config_path: config_path,
          out: out,
          simmer_dir: simmer_dir
        )

        expect(results.pass?).to be false
      end

      it 'records error' do
        results = described_class.run(
          spec_path,
          config_path: config_path,
          out: out,
          simmer_dir: simmer_dir
        )

        expect(results.runner_results.first.errors).to include(/execution expired/)
      end
    end

    describe '#make_runner' do
      let(:spoon_path)  { File.join('spec', 'mocks', 'load_noc_list_bad_output') }
      let(:args)        { '' }

      subject do
        described_class.make_runner(
          described_class.make_configuration(
            config_path: config_path,
            simmer_dir: simmer_dir
          ),
          $stdout
        )
      end

      it 'sets Pdi::Spoon#timeout_in_seconds from configuration' do
        actual   = subject.spoon_client.spoon.executor.timeout_in_seconds
        expected = config.dig('spoon_client', 'timeout_in_seconds')

        expect(actual).to eq(expected)
      end
    end
  end

  context 'when the fixtures are missing' do
    let(:spec_path)   { File.join('spec', 'fixtures', 'specifications', 'missing_fixtures.yaml') }
    let(:simmer_dir)  { File.join('spec', 'simmer_spec') }
    let(:out)         { Out.new }
    let(:config_path) { stage_simmer_config(spoon_path, args) }

    context 'when pdi does not do anything but does not fail' do
      let(:spoon_path)  { File.join('spec', 'mocks', 'spoon') }
      let(:args)        { 0 }

      it 'fails' do
        results = described_class.run(
          spec_path,
          config_path: config_path,
          out: out,
          simmer_dir: simmer_dir
        )

        expect(results.pass?).to be false
      end

      it 'records error' do
        results = described_class.run(
          spec_path,
          config_path: config_path,
          out: out,
          simmer_dir: simmer_dir
        )

        expect(results.runner_results.first.errors).to include(/fixture missing/)
      end
    end
  end
end
