# frozen_string_literal: true

class CmsTags < ActiveRecord::Migration[5.2]
  def up
    Comfy::Cms::Layout.all.each do |layout|
      layout.content = layout.content.gsub(%r{\{\{ ?cms:page:([\w/]+) ?\}\}}, '{{ cms:text \1 }}') if layout.content.is_a? String

      # {{cms:page:page_header:string}} -> {{ cms:text page_header }}
      layout.content = layout.content.gsub(/\{\{ ?cms:page:([\w]+):string ?\}\}/, '{{ cms:text \1 }}') if layout.content.is_a? String

      # {{cms:page:content:rich_text}} -> {{ cms:wysiwyg content }}
      layout.content = layout.content.gsub(/\{\{ ?cms:page:([\w]+):rich_text ?\}\}/, '{{ cms:wysiwyg \1 }}') if layout.content.is_a? String
      layout.content = layout.content.gsub(/\{\{ ?cms:page:([\w]+):([^:]*) ?\}\}/, '{{ cms:\2 \1 }}') if layout.content.is_a? String
      if layout.content.is_a? String
        layout.content = layout.content.gsub(/\{\{ ?cms:field:([\w]+):string ?\}\}/, '{{ cms:text \1, render: false }}')
      end
      if layout.content.is_a? String
        layout.content = layout.content.gsub(/\{\{ ?cms:field:([\w]+):([^:]*) ?\}\}/, '{{ cms:\2 \1, render: false }}')
      end

      # {{ cms:partial:main/homepage }} -> {{ cms:partial "main/homepage" }}
      if layout.content.is_a? String
        layout.content = layout.content.gsub(%r{\{\{ ?cms:asset:([\w/-]+):([\w/-]+):([\w/-]+) ?\}\}}, '{{ cms:asset \1 type: \2 as: tag}}')
      end
      layout.content = layout.content.gsub(%r{\{\{ ?cms:partial:([\w/]+) ?\}\}}, '{{ cms:partial \1 }}') if layout.content.is_a? String
      layout.content = layout.content.gsub(%r{\{\{ ?cms:(\w+):([\w/-]+) ?\}\}}, '{{ cms:\1 \2 }}') if layout.content.is_a? String
      if layout.content.is_a? String
        layout.content = layout.content.gsub(%r{\{\{ ?cms:(\w+):([\w/-]+):([\w/-]+):([\w/-]+) ?\}\}}, '{{ cms:\1 \2 \3 \4}}')
      end
      layout.content = layout.content.gsub(/\{\{ ?cms:(\w+):([\w]+):([^:]*) ?\}\}/, '{{ cms:\1 \2, "\3" }}') if layout.content.is_a? String
      layout.content = layout.content.gsub(/cms:rich_text/, 'cms:wysiwyg') if layout.content.is_a? String
      layout.content = layout.content.gsub(/cms:integer/, 'cms:number') if layout.content.is_a? String
      if layout.content.is_a? String
        layout.content = layout.content.gsub(/cms: string/, 'cms:text')
      end # probably a result of goofing one of the more general regexps
      if layout.content.is_a? String
        layout.content = layout.content.gsub(%r{\{\{ ?cms:page_file ([\w/]+) ?\}\}}, '{{ cms:file \1, render: false }}')
      end
      if layout.content.is_a? String
        layout.content = layout.content.gsub(/<!-- {{ cms:text (\w+)_slide, render: false }} -->/, "{{ cms:text \1, render: false }}")
      end

      layout.save if layout.changed?
    end
    Comfy::Cms::Fragment.all.each do |fragment|
      # {{ cms:partial:main/homepage }} -> {{ cms:partial "main/homepage" }}
      fragment.datetime = fragment.updated_at if fragment.datetime.nil?
      if fragment.content.is_a? String
        fragment.content = fragment.content.gsub(%r{\{\{ ?cms:partial:([\w/]+) ?\}\}}, '{{ cms:partial \1 }}')
      end

      fragment.content = fragment.content.gsub(/\{\{ ?cms:page:([\w]+):string ?\}\}/, '{{ cms:text \1 }}') if fragment.content.is_a? String
      if fragment.content.is_a? String
        fragment.content = fragment.content.gsub(/\{\{ ?cms:page:([\w]+):rich_text ?\}\}/, '{{ cms:wysiwyg \1 }}')
      end

      fragment.content = fragment.content.gsub(%r{\{\{ ?cms:page:([\w/]+) ?\}\}}, '{{ cms:text \1 }}') if fragment.content.is_a? String
      fragment.content = fragment.content.gsub(/\{\{ ?cms:page:([\w]+):([^:]*) ?\}\}/, '{{ cms:\2 \1 }}') if fragment.content.is_a? String
      if fragment.content.is_a? String
        fragment.content = fragment.content.gsub(/\{\{ ?cms:field:([\w]+):([^:]*) ?\}\}/, '{{ cms:\2 \1, render: false }}')
      end

      fragment.content = fragment.content.gsub(/\{\{ ?cms:(\w+):([\w]+) ?\}\}/, '{{ cms:\1 \2 }}') if fragment.content.is_a? String
      if fragment.content.is_a? String
        fragment.content = fragment.content.gsub(/\{\{ ?cms:(\w+):([\w]+):([^:]*) ?\}\}/, '{{ cms:\1 \2, "\3" }}')
      end
      fragment.save if fragment.changed?
    end

    # With the change from Block to Fragment, Revision.data hash keys need to be updated
    Comfy::Cms::Revision.all.each do |revision|
      next if revision.data['blocks_attributes'].blank?

      revision.data['fragments_attributes'] = revision.data['blocks_attributes']
      revision.data.delete('blocks_attributes')
      revision.save
    end
  end
end
