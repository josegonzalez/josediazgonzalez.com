require "test_helper"
require "tmpdir"

class DitaaBlockTest < Minitest::Test
  FakeSite = Struct.new(:config, :source, :static_files)

  def test_renders_code_fallback_and_creates_output_dir_without_ditaa
    skip "ditaa is installed" if system("which ditaa > /dev/null 2>&1")

    Dir.mktmpdir do |dir|
      site = FakeSite.new({}, dir, [])
      template = Liquid::Template.parse("{% ditaa -S %}\n+--+\n|ab|\n+--+\n{% endditaa %}")
      output = template.render!({}, registers: { site: site })

      assert_match %r{\A<pre><code>\+--\+\n\|ab\|\n\+--\+\n</code></pre>\z}, output
      assert File.directory?(File.join(dir, "images", "ditaa"))
    end
  end
end
