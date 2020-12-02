# coding: utf-8
require 'cli/ui'
require 'cli/ui/frame/frame_stack'
require 'cli/ui/frame/frame_style'

module CLI
  module UI
    class Wrap
      def initialize(input)
        @input = input
      end

      def wrap
        max_width = Terminal.width - Frame.prefix_width
        width = 0
        final = []
        # Create an alternation of format codes of parameter lengths 1-20, since + and {1,n} not allowed in lookbehind
        format_codes = (1..20).map { |n| /\x1b\[[\d;]{#{n}}m/ }.join('|')
        codes = ''
        @input.split(/(?=\s|\x1b\[[\d;]+m|\r)|(?<=\s|#{format_codes})/).each do |token|
          case token
          when '\x1B[0?m'
            codes = ''
            final << token
          when /\x1b\[[\d;]+m/
            codes += token # Track in use format codes so that they are resent after frame coloring
            final << token
          when "\n"
            final << "\n#{codes}"
            width = 0
          when /\s/
            token_width = ANSI.printing_width(token)
            if width + token_width <= max_width
              final << token
              width += token_width
            else
              final << "\n#{codes}"
              width = 0
            end
          else
            token_width = ANSI.printing_width(token)
            if width + token_width <= max_width
              final << token
              width += token_width
            else
              final << "\n#{codes}"
              if token_width > max_width
                parts = break_word(token, max_width)
                width = ANSI.printing_width(parts.last)
                final << parts.join("\n#{codes}")
              else
                final << token
                width = token_width
              end
            end
          end
        end
        final.join
      end

      def break_word(word, max_width)
        parts = []
        next_word = +''
        word.each_char do |c|
          if ANSI.printing_width(next_word + c) <= max_width
            next_word += c
          else
            parts << next_word
            next_word = +''
          end
        end
        parts << next_word unless next_word == ''
        parts
      end
    end
  end
end
