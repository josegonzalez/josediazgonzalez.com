require "test_helper"
require "tmpdir"

class SassConverterTest < Minitest::Test
  def test_uses_dart_sass_converter
    version = Gem.loaded_specs.fetch("jekyll-sass-converter").version
    assert_operator version, :>=, Gem::Version.new("3.0.0")
  end

  def test_compiles_scss
    Dir.mktmpdir do |dir|
      config = Jekyll.configuration("source" => dir, "destination" => File.join(dir, "_site"), "quiet" => true)
      converter = Jekyll::Site.new(config).find_converter_instance(Jekyll::Converters::Scss)

      output = converter.convert("$color: #333;\na { b { color: $color; } }")
      assert_match(/a b\s*\{\s*color:\s*#333;?\s*\}/, output)
    end
  end
end
