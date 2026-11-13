require "test_helper"

class FiltersTest < Minitest::Test
  class Filters
    include Liquid::ExtendedFilters
  end

  def setup
    @filters = Filters.new
  end

  def test_nokogiri_is_patched_for_css_selector_redos
    assert_operator Gem::Version.new(Nokogiri::VERSION), :>=, Gem::Version.new("1.19.3")
  end

  def test_html_truncatewords_returns_short_text_unchanged
    html = "<p>Hello <strong>world</strong></p>"
    assert_equal html, @filters.html_truncatewords(html)
  end

  def test_html_truncatewords_truncates_long_text_and_keeps_tags
    html = "<p>Hello <strong>wonderful</strong> world</p>"
    result = @filters.html_truncatewords(html, 10)
    assert_equal "<p>Hello <strong>wond</strong></p>", result
    assert_equal 10, Nokogiri::HTML::DocumentFragment.parse(result).inner_text.length
  end

  def test_html_truncatewords_appends_ellipsis_within_length
    html = "<p>Hello wonderful world</p>"
    result = @filters.html_truncatewords(html, 10, "...")
    assert_equal "<p>Hello w</p>...", result
  end

  def test_preview_splits_on_delimiter
    text = "<p>Intro</p><!-- end_preview --><p>Rest</p>"
    assert_equal "<p>Intro</p>", @filters.preview(text)
  end

  def test_preview_truncates_without_delimiter
    text = "<p>#{"a" * 250}</p>"
    assert_equal "<p>#{"a" * 200}</p>", @filters.preview(text)
  end

  def test_tokenize_removes_stop_words_numbers_and_duplicates
    result = @filters.tokenize("The Quick fox's 2024 fox", "Jumped over the dog")
    assert_equal %w[dog fox foxs jumped quick], result
  end
end
