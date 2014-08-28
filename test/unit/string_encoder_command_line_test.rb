require 'test_helper'

module Scm::Parsers
  class StringEncoderCommandLineTest < Scm::Test
    def test_encoding_invalid_characters
      invalid_text_path =
        File.expand_path('../../data/invalid-utf-word', __FILE__)

      string = %x[cat #{ invalid_text_path } \
        | #{ Scm::Adapters::AbstractAdapter.new.string_encoder } ]

      assert_equal true, string.valid_encoding?
    end
  end
end
