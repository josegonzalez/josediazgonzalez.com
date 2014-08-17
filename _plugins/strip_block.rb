# Replaces multiple newlines and whitespace
# between them with one newline

module Jekyll
  class StripBlock < Liquid::Block

    def render(context)
      super.gsub /\n\s*\n/, "\n"
    end

  end
end

Liquid::Template.register_tag('strip', Jekyll::StripBlock)
