module Gitlab
  module Diff
    class Highlight
      attr_reader :diff_file, :diff_lines, :raw_lines, :repository

      delegate :old_path, :new_path, :old_sha, :new_sha, to: :diff_file, prefix: :diff

      def initialize(diff_lines, repository: nil)
        @repository = repository

        if diff_lines.is_a?(Gitlab::Diff::File)
          @diff_file = diff_lines
          @diff_lines = @diff_file.diff_lines
        else
          @diff_lines = diff_lines
        end
        @raw_lines = @diff_lines.map(&:text)
      end

      def highlight
        @diff_lines.map.with_index do |diff_line, i|
          diff_line = diff_line.dup
          # ignore highlighting for "match" lines
          next diff_line if diff_line.meta?

          rich_line = highlight_line(diff_line) || diff_line.text

          if line_inline_diffs = inline_diffs[i]
            rich_line = InlineDiffMarker.new(diff_line.text, rich_line).mark(line_inline_diffs)
          end

          diff_line.text = rich_line

          diff_line
        end
      end

      private

      def highlight_line(diff_line)
        return unless diff_file && diff_file.diff_refs

        rich_line =
          if diff_line.unchanged? || diff_line.added?
            new_lines[diff_line.new_pos - 1]
          elsif diff_line.removed?
            old_lines[diff_line.old_pos - 1]
          end

        # Only update text if line is found. This will prevent
        # issues with submodules given the line only exists in diff content.
        if rich_line
          line_prefix = diff_line.text =~ /\A(.)/ ? $1 : ' '
          "#{line_prefix}#{rich_line}".html_safe
        end
      end

      def inline_diffs
        @inline_diffs ||= InlineDiff.for_lines(@raw_lines)
      end

      def old_lines
        return unless diff_file
        @old_lines ||= Gitlab::Highlight.highlight_lines(self.repository, diff_old_sha, diff_old_path)
      end

      def new_lines
        return unless diff_file
        @new_lines ||= Gitlab::Highlight.highlight_lines(self.repository, diff_new_sha, diff_new_path)
      end
    end
  end
end
