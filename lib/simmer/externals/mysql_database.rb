# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'mysql_database/sql_fixture'

module Simmer
  module Externals
    class MysqlDatabase
      def initialize(config, fixture_set)
        config = (config || {}).symbolize_keys

        @client        = Mysql2::Client.new(config)
        @fixture_set   = fixture_set
        exclude_tables = Array(config[:exclude_tables]).map(&:to_s)
        @table_names   = retrieve_table_names - exclude_tables

        freeze
      end

      def records(table, columns = [])
        query = "SELECT #{sql_select_params(columns)} FROM #{table}"

        client.query(query).to_a
      end

      def seed!(specification)
        sql_statements = seed_sql_statements(specification)

        shameless_execute(sql_statements)

        sql_statements.length
      end

      def clean!
        sql_statements = clean_sql_statements

        shameless_execute(sql_statements)

        sql_statements.length
      end

      private

      attr_reader :client, :fixture_set, :table_names

      def sql_select_params(columns)
        Array(columns).any? ? Array(columns).map { |c| client.escape(c) }.join(',') : '*'
      end

      def seed_sql_statements(specification)
        fixture_names = specification.stage.fixtures

        fixture_names.map do |fixture_name|
          fixture = fixture_set.get!(fixture_name)

          SqlFixture.new(client, fixture).to_sql
        end
      end

      def clean_sql_statements
        table_names.map do |table_name|
          "TRUNCATE #{table_name}"
        end
      end

      def shameless_execute(sql_statements)
        execute(disable_checks_sql_statement)
        execute(sql_statements)
        execute(enable_checks_sql_statement)
      end

      def execute(*sql_statements)
        sql_statements.flatten.each do |sql_statement|
          client.query(sql_statement)
        end

        nil
      end

      def disable_checks_sql_statement
        'SET @@foreign_key_checks = 0'
      end

      def enable_checks_sql_statement
        'SET @@foreign_key_checks = 1'
      end

      def retrieve_table_names
        schema = client.escape(client.query_options[:database].to_s)
        sql = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '#{schema}'"

        client.query(sql).to_a.map { |v| v['TABLE_NAME'].to_s }
      end
    end
  end
end
