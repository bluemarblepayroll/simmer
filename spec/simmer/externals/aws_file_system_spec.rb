# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'spec_helper'

describe Simmer::Externals::AwsFileSystem do
  let(:bucket_store)         { {} }
  let(:bucket_name)          { 'test' }
  let(:encryption)           { 'AES256' }
  let(:files_dir)            { File.join('spec', 'fixtures') }
  let(:specification_path)   { File.join('specifications', 'load_noc_list.yaml') }
  let(:specification_config) { yaml_fixture(specification_path).merge(path: specification_path) }
  let(:specification)        { Simmer::Specification.make(specification_config) }

  let(:aws_s3_client_stub) do
    Aws::S3::Client.new(stub_responses: true).tap do |client|
      client.stub_responses(:get_object, lambda { |context|
        obj = bucket_store[context.params[:key]]
        obj || 'NoSuchKey'
      })

      client.stub_responses(:put_object, lambda { |context|
        bucket_store[context.params[:key]] = { body: context.params[:body] }
        {}
      })

      client.stub_responses(:list_objects, lambda { |_context|
        contents = bucket_store.keys.map { |k| OpenStruct.new(key: k) }

        OpenStruct.new(contents: contents)
      })
    end
  end

  subject { described_class.new(aws_s3_client_stub, bucket_name, encryption, files_dir) }

  specify '#write transfers all files' do
    subject.write(specification)

    expected = {
      'input/noc_list.csv' => {
        body: "call_sign,first,last\niron_man,Tony,Stark\nhulk,Bruce,Banner\n"
      }
    }

    expect(bucket_store).to eq(expected)
  end
end
