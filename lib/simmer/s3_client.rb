# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module Simmer
  class S3Client
    attr_reader :bucket, :client, :encryption

    def initialize(config)
      config = (config || {}).symbolize_keys

      @client = Aws::S3::Client.new(
        access_key_id: config[:access_key_id],
        secret_access_key: config[:secret_access_key],
        region: config[:region]
      )

      @bucket     = Aws::S3::Bucket.new(name: config[:bucket], client: client)
      @encryption = config[:encryption]

      freeze
    end

    def seed!(specification)
      s3_files = specification.stage.s3_files

      s3_files.each do |s3_file|
        path = File.join('spec', 'files', s3_file.path)

        write(s3_file.key, path)
      end

      s3_files.length
    end

    def clean!
      bucket.objects.inject(0) do |memo, object|
        object.delete

        memo + 1
      end
    end

    private

    def write(key, local_path)
      File.open(local_path, 'rb') do |file|
        bucket.object(key).put(
          body: file,
          server_side_encryption: encryption
        )
      end

      nil
    end
  end
end
