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

      def initialize(aws_s3_client, bucket, encryption, files_dir)
        raise ArgumentError, 'aws_s3_client is required' unless aws_s3_client
        raise ArgumentError, 'bucket is required'        if bucket.to_s.empty?

        assert_bucket_name(bucket)

        @aws_s3_client = aws_s3_client
        @bucket        = bucket.to_s
        @encryption    = encryption
        @files_dir     = files_dir

        freeze
      end

      def write!(specification)
        files = specification.stage.files

        files.each do |file|
          src = File.join(files_dir, file.src)

          write_single(file.dest, src)
        end

        files.length
      end

      def clean!
        response    = aws_s3_client.list_objects(bucket: bucket)
        objects     = response.contents
        keys        = objects.map(&:key)
        delete_keys = keys.map { |key| { key: key } }

        return 0 if objects.length.zero?

        aws_s3_client.delete_objects(
          bucket: bucket,
          delete: {
            objects: delete_keys
          }
        )

        delete_keys.length
      end

      private

      attr_reader :aws_s3_client, :bucket, :encryption, :files_dir

      def write_single(dest, src)
        src = File.expand_path(src)

        File.open(src, 'rb') do |file|
          aws_s3_client.put_object(
            body: file.read,
            bucket: bucket,
            key: dest,
            server_side_encryption: encryption
          )
        end

        nil
      end

      def assert_bucket_name(name)
        return if name.to_s.end_with?(BUCKET_SUFFIX)

        raise ArgumentError, "bucket (#{name}) must end in #{BUCKET_SUFFIX}"
      end
    end
  end
end
