# encoding: utf-8
module Infoboxer
  MediaWiki::Traits.for('en.wikipedia.org') do
    templates do
      # https://en.wikipedia.org/wiki/Category:Wikipedia_character-substitution_templates
      # ---------------------------------------------------------------------------------
      # Extracted semi-automatically
      # TODO: fully automatical extraction
      literal(
        '&',
        ';',
        '=',
        '?',
        '—',
        '1/2',
        '1/3',
        '1/4',
        '2/3',
        '3/4',
      )
      replace(
        '!!' => '||',
        '!(' => '[',
        '!((' => '[[',
        '!-' => '|-',
        '!:' => ':',
        '&' => '&',
        "'" => " '",
        "''" => '″',
        "'s" => "'‍s",
        '(' => '{',
        '((' => '{{',
        '(((' => '{{{',
        ')' => '}',
        ')!' => ']',
        '))' => '}}',
        '))!' => ']]',
        ')))' => '}}}',
        'Asterisk' => '*',
        'Colon' => ':',
        'Em dash' => '—',
        'Gc' => "†",
        'Ibeam' => 'I',
        'Long dash' => ' ——— ',
        'Nbhyph' => '‑',
        'Number sign' => '#',
        'Shy' => '­', # soft hyphen
        'Single space' => "' ",
        'Space single' => " '",
        'Spaced ndash' => ' – ',
        'Square bracket close' => ']',
        'Square bracket open' => '[',
        'Zwsp' => '',
        '\\' => ' / ',
        '`' => "'",
        '·' => ' · ',
        '‘' => '‘',
        '•' => ' • ',
      )

      # https://en.wikipedia.org/wiki/Category:Line-handling_templates
      # ------------------------------------------------------------------
      replace(
        '-' => "\n",
        'Break' => "\n", # FIXME: in fact, break has optional parameter "how many breaks"
        'Crlf' => "\n",  # FIXME: in fact, alias for break, should have DSL syntax for it!
        'Crlf2' => "\n",
        
      )
      show(
        'Allow wrap',
        'Nowrap',
          'j', 'nobr', 'nobreak', # aliases for Nowrap
        'nowraplinks',
      )
      # inflow_template('Normalwraplink') # TODO: tricky

      # https://en.wikipedia.org/wiki/Category:List_formatting_and_function_templates
      # -----------------------------------------------------------------------------
      # NB: it's enough for most cases to have all list-representing templates
      # just navigable inside and rendered as space-separated list of entries
      show(
        'Br separated entries',
        'Bulleted list',
        'Collapsible list',
        'Comma separated entries',
        'Hlist',
        'Flatlist',
        'Flowlist',
        'Pagelist',
        'Ordered list',
        'Plainlist',
        'Space separated entries',
        'Toolbar',
      )

      # https://en.wikipedia.org/wiki/Category:Wikipedia_XHTML_tag-replacing_templates
      # ------------------------------------------------------------------------------

      show(
        # Font size
        'Small',
        'Smaller',
        'Midsize',
        'Larger',
        'Big',
        'Large',
        'Huge',

        # Align
        'left',
        'Center',
        'Right',

        # Simple style
        'Em',
        'Kbd',
        'Var',
        'Varserif',
        'Samp',
        'Strikethrough',
        'Strong',
        'Sub',
        'Sup',
        'Underline',

        # FIXME: should do something wiser
        'Pre',
        'Pre2',
        'Code'
      )

      template 'Abbr' do
        def children
          fetch('1')
        end
      end
      # TODO: has aliases: {{Define}}, {{Explain}}, {{Tooltip}}

      template 'Align' do
        def children
          fetch('2')
        end
      end

      template 'Dfn' do
        def children
          fetch('1')
        end
      end

      template 'Resize' do
        def children
          unnamed_variables.count < 2 ? fetch('1') : fetch('2')
        end
      end

      template 'Font' do
        def children
          res = fetch('text')
          res.empty? ? fetch('1') : res
        end
      end

      # https://en.wikipedia.org/wiki/Category:Text_color_templates
      show(
        'white', 'silver (color)', 'gray', 'black', 'pink', 'red', 'darkred',
        'maroon', 'brown', 'orange (color)', 'gold (color)', 'yellow', 'olive',
        'lime', 'green', 'aqua (color)', 'cyan', 'teal', 'blue', 'navy (color)',
        'purple', 'fuchsia', 'magenta'
      )
      
      # Some most popular templates, without categorical splitting
      # https://en.wikipedia.org/wiki/Wikipedia:Database_reports/Templates_transcluded_on_the_most_pages
      # ------------------------------------------------------------------------------------------------
      # Currently scanned by eyes up to 250-th line, which is used in 130549 articles, according to the
      # page - which, though, is dramatically outdated.

      template 'Stub', match: /-stub$/ do
        def stub?
          true
        end
      end

      template 'Infobox', match: /^Infobox/i do
        def infobox?
          true
        end
      end

      template 'Coord' do
        def model
          @model ||= begin
            npos = lookup_children(text: /^N|S$/).first.index rescue nil
            case npos
            when 1
              :decimal
            when 2
              :min
            when 3
              :sec
            else
              :decimal_sign
            end
          end
        end

        def lat
          case model
          when :decimal
            '%s°%s′%s' % fetch('1', '2').map(&:text)
          when :decimal_sign
            fetch('1').text
          when :min
            '%s°%s′%s' % fetch('1', '2', '3').map(&:text)
          when :sec
            '%s°%s′%s″%s' % fetch('1', '2', '3', '4').map(&:text)
          end
        end

        def lng
          case model
          when :decimal, :decimal_sign
            fetch('1').text
          when :min
            '%s°%s′%s' % fetch('1', '2', '3').map(&:text)
          when :sec
            '%s°%s′%s″%s' % fetch('1', '2', '3', '4').map(&:text)
          end
        end
      end

      template 'Convert' do
        def value1
          fetch('1').text
        end

        ALLOW_BETWEEN = ['-;', '–',
          'and', '&', 'and(-)', ', and',
          'or', ', or',
          'to', 'to(-)', 'to about',
          '+/-', '±', '+',
          'by', 'x', '×', 'x',
        ]

        def between
          ALLOW_BETWEEN.include?(fetch('2').text) ? fetch('2').text : nil
        end

        def value2
          between ? fetch('3').text : nil
        end

        def measure_from
          between ? fetch('4').text : fetch('2').text
        end
        
        def measure_to
          between ? fetch('5').text : fetch('3').text
        end
        
        def text
          [value1, between, value2, measure_from].compact.join(' ')
        end
      end

      template 'Age' do
        def from
          fetch_date('1', '2', '3')
        end

        def to
          fetch_date('4', '5', '6') || Date.today
        end

        def value
          (to - from).to_i / 365 # FIXME: obviously
        end

        def text
          "#{value} years"
        end
      end

      template 'Birth date and age' do
        def date
          fetch_date('1', '2', '3')
        end

        def text
          date.to_s
        end
      end
      # TODO: aliased as bda

      template 'Birth date' do
        def date
          fetch_date('1', '2', '3')
        end

        def text
          date.to_s
        end
      end
      # TODO: aliased as dob

      template 'Time ago' do
        def text
          str = fetch('1').text
          begin
            date = Date.parse(str)
            "#{(Date.today - date).to_i} days ago" # not trying complext time_distance_in_words formatting here
          rescue ArgumentError
            str
          end
        end
      end

      template 'Flagcountry' do # very popular instead of country name
        def children
          fetch('1')
        end
      end

      template 'Flag' do # very popular instead of country name
        def children
          fetch('1')
        end
      end

      show 'Plural'

      template 'URL' do
        def children
          unnamed_variables.count > 1 ? fetch('2') : fetch('1')
        end
      end

      # TODO: extremely popular:
      # Str left - https://en.wikipedia.org/wiki/Category:String_manipulation_templates
      # Rnd - https://en.wikipedia.org/wiki/Category:Mathematical_function_templates

      # TODO: useful categories
      # https://en.wikipedia.org/wiki/Category:Date_mathematics_templates
      # https://en.wikipedia.org/wiki/Category:Mathematical_function_templates
      # https://en.wikipedia.org/wiki/Category:Wikipedia_formatting_and_function_templates
      # https://en.wikipedia.org/wiki/Category:Semantic_markup_templates
      # https://en.wikipedia.org/wiki/Category:Quotation_templates
      # https://en.wikipedia.org/wiki/Category:Typing-aid_templates
      # https://en.wikipedia.org/wiki/Category:Inline_spacing_templates
      # https://en.wikipedia.org/wiki/Category:Sorting_templates
      # https://en.wikipedia.org/wiki/Wikipedia:Database_reports/Templates_transcluded_on_the_most_pages
    end
  end
end
