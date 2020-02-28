# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module Simmer
  module Externals
    # Provides the implementation for using AWS S3 as a destination file store.
    class AwsFileSystem
      BUCKET_SUFFIX = 'test'

      private_constant :BUCKET_SUFFIX

      def initialize(config, files_dir)
        config = (config || {}).symbolize_keys

        client = Aws::S3::Client.new(
          access_key_id: config[:access_key_id],
          secret_access_key: config[:secret_access_key],
          region: config[:region]
        )

        bucket_name = config[:bucket].to_s
        assert_bucket_name(bucket_name)

        @bucket     = Aws::S3::Bucket.new(name: bucket_name, client: client)
        @encryption = config[:encryption]
        @files_dir  = files_dir

        freeze
      end

      def write(specification)
        files = specification.stage.files

        files.each do |file|
          src = File.join(files_dir, file.src)

          write_single(file.dest, src)
        end

        files.length
      end

      def clean
        bucket.objects.inject(0) do |memo, object|
          object.delete

          memo + 1
        end
      end

      private

      attr_reader :bucket, :encryption, :files_dir

      def write_single(dest, src)
        src = File.expand_path(src)

        File.open(src, 'rb') do |file|
          bucket.object(dest).put(
            body: file,
            server_side_encryption: encryption
          )
        end

        nil
      end

      def assert_bucket_name(name)
        return if name.end_with?(BUCKET_SUFFIX)

        raise ArgumentError, "bucket (#{name}) must end in #{BUCKET_SUFFIX}"
      end
    end
  end
end
