module Jekyll

  class IndexPage < Page
    def initialize(site, base, dir, identifier, singular)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), "#{singular}_index.html")
      self.data[singular] = identifier

      title_prefix = site.config["#{singular}_title_prefix"] || 'Page: '
      self.data['title'] = "#{title_prefix}#{identifier}"
    end
  end

  class TagPageGenerator < Generator
    safe true

    def generate(site)
      if site.layouts.key? 'tag_index'
        dir = site.config['tag_dir'] || 'tags'
        site.tags.keys.each do |tag|
          site.pages << IndexPage.new(site, site.source, File.join(dir, tag), tag, 'tag')
        end
      end
    end
  end

  class CategoryPageGenerator < Generator
    safe true

    def generate(site)
      if site.layouts.key? 'category_index'
        dir = site.config['category_dir'] || 'categories'
        site.categories.keys.each do |category|
          site.pages << IndexPage.new(site, site.source, File.join(dir, category), category, 'category')
        end
      end
    end
  end

end
