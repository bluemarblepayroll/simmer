#!/usr/bin/env ruby
# frozen_string_literal: true

require './spec/db_helper'

puts 'bad output!'

db_helper_client.query("UPDATE agents SET first = 'bruce', last = 'banner' WHERE call_sign = 'hulk'")
db_helper_client.query("UPDATE agents SET first = 'tony', last = 'stark' WHERE call_sign = 'iron_man'")
