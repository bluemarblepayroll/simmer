# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'spec_helper'

describe Simmer::Suite::Summerizer do
  describe 'when the suite passes' do
    it 'lets the user know that the suite ended successfully'
  end

  describe 'when the suite fails' do
    it 'lets the user know of the failure, the count of failed tests, and a list of the failed test'
  end
end
