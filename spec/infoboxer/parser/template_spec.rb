require 'infoboxer/parser'

module Infoboxer
  describe Parser, 'templates' do
    let(:ctx) { Parser::Context.new(source) }
    let(:parser) { Parser.new(ctx) }

    let(:nodes) { parser.inline }
    let(:template) { nodes.first }

    subject { template }

    context 'simplest' do
      let(:source) { '{{the name}}' }

      it { is_expected.to be_a(Tree::Template) }
      its(:name) { is_expected.to eq 'the name' }
    end

    context 'with unnamed variable' do
      let(:source) { '{{the name|en}}' }

      it { is_expected.to be_a(Tree::Template) }
      its(:name) { is_expected.to eq 'the name' }
      its(:variables) { is_expected.to eq [Tree::Var.new('1', Tree::Text.new('en'))] }
    end

    context 'with named variable' do
      let(:source) { '{{the name|lang=en}}' }

      it { is_expected.to be_a(Tree::Template) }
      its(:name) { is_expected.to eq 'the name' }
      its(:variables) { is_expected.to eq [Tree::Var.new('lang', Tree::Text.new('en'))] }
    end

    context 'with empty variable' do
      let(:source) { '{{the name|lang=}}' }

      it { is_expected.to be_a(Tree::Template) }
      its(:name) { is_expected.to eq 'the name' }
      its(:variables) { is_expected.to eq [Tree::Var.new('lang')] }
    end

    context 'with named and unnamed mixed' do
      let(:source) { '{{the name|test1|foo=bar|test2}}' }

      it 'should have variables named consistently' do
        expect(subject.variables.map(&:name)).to eq %w[1 foo 2]
      end
    end

    context 'with empty line' do
      let(:source) { '{{the name|}}' }

      it { is_expected.to be_a(Tree::Template) }
      its(:name) { is_expected.to eq 'the name' }
      its(:variables) { is_expected.to eq [] }
    end

    context 'with "=" symbol in variable' do
      let(:source) { '{{the name|formula=1+2=3}}' }

      its(:variables) { is_expected.to eq [Tree::Var.new('formula', Tree::Text.new('1+2=3'))] }
    end

    context 'with link in variable' do
      let(:source) { '{{the name|[[Argentina|Ar]]}}' }

      it { is_expected.to be_a(Tree::Template) }
      its(:name) { is_expected.to eq 'the name' }
      its(:variables) {
        is_expected.to eq \
          [
            Tree::Var.new('1', [Tree::Wikilink.new('Argentina', Tree::Text.new('Ar'))])
          ]
      }
    end

    context 'with paragraphs in variable' do
      let(:source) { "{{the name|var=some\nmultiline\n''text''}}" }

      it { is_expected.to be_a(Tree::Template) }
      it 'should preserve all content' do
        expect(subject.variables.first.children.map(&:class)).to eq [Tree::Text, Tree::Paragraph]
      end
    end

    # TODO: due to templates flowing thingy
    xcontext 'with newlines before nested template' do
      let(:source) { "{{the name|var=\n {{nested}}}}" }

      it { is_expected.to be_a(Tree::Template) }
      it 'should preserve all content' do
        expect(subject.variables.first.children).to all(be_a(Tree::Template))
      end
    end

    context 'with newlines before variable name' do
      let(:source) { "{{the name|\nvar=test}}" }

      it { is_expected.to be_a(Tree::Template) }
      it 'should preserve all content' do
        expect(subject.variables.first.name).to eq 'var'
      end
    end

    context 'with spaces before variable name' do
      let(:source) { '{{the name| var=test}}' }

      it { is_expected.to be_a(Tree::Template) }
      it 'should preserve all content' do
        expect(subject.variables.first.name).to eq 'var'
      end
    end

    context 'with newline+space before next var' do
      let(:source) { "{{the name|var=test\n |var2=foo}}" }

      it { is_expected.to be_a(Tree::Template) }
      it 'should preserve all content' do
        expect(subject.variables.first.children).to eq [Tree::Text.new('test')]
      end
    end

    context 'with <ref> and other template in variable' do
      let(:source) { "{{the name|<ref>some\nmultiline\nreference</ref> {{and|other-template}}|othervar}}" }

      it { is_expected.to be_a(Tree::Template) }
      its(:'variables.count') { is_expected.to eq 2 }
    end

    context 'with other template in variable - newlines' do
      let(:source) { "{{the name|first=\n {{\nother-template\n }}\n| othervar}}" }

      it { is_expected.to be_a(Tree::Template) }
      its(:'variables.count') { is_expected.to eq 2 }
    end

    context 'with complex lists inside' do
      let(:source) {
        unindent(%{
        {{Infobox country
        |footnote_a = {{note|note-lang}}''[[De facto]]'' at all government levels.{{efn-ua|name=es|Though not declared official ''[[de jure]]'', the Spanish language is the only one used in the wording of laws, decrees, resolutions, official documents and public acts.}} In addition, some provinces have official ''[[de jure]]'' languages:
        :{{,}}[[Guaraní language|Guaraní]] in [[Corrientes Province]].<ref name=gn>{{cite Argentine law|jur=CN|l=5598|date=22 de octubre de 2004}}</ref>
        :{{,}}[[Kom language (South America)|Kom]], [[Moqoit language|Moqoit]] and [[Wichi language|Wichi]], in [[Chaco Province]].<ref name=kom>{{cite Argentine law|jur=CC|l=6604|bo=9092|date=28 de julio de 2010}}</ref>
        |footnote_b = {{note|note-train}}Trains ride on left.
        }}
      })}

      it { is_expected.to be_a(Tree::Template) }
      its(:'variables.count') { is_expected.to eq 2 }
    end

    context 'with simple variable inside' do
      let(:source) { %{{{some template|lang=en|wtf|text=not a ''parameter''}}} }

      its(:'variables.count') { is_expected.to eq 3 }
    end

    context 'magic words' do
      let(:source) { %{{{formatnum:{{#expr: 14.3 * 2.589988110336 round 1}} }}} }

      it { is_expected.to be_a(Tree::Template) }
      its(:name) { is_expected.to eq 'formatnum' }
      its(:'variables.count') { is_expected.to eq 1 }
      its(:'variables.first.name') { is_expected.to eq '1' }
      context 'magic inside magic' do
        subject { template.variables.first.children.first }

        it { is_expected.to be_a(Tree::Template) }
        its(:name) { is_expected.to eq '#expr' }
      end
    end

    context 'and now for really sick stuff!' do
      let(:source) { File.read('spec/fixtures/large_infobox.txt') }

      it { is_expected.to be_a(Tree::Template) }
      its(:"variables.count") { is_expected.to eq 87 }
    end

    context 'Titanic' do
      let(:source) {
        %{{{Infobox ship image
| Ship image = [[File:RMS Titanic 3.jpg|300px]]
| Ship caption = RMS ''Titanic'' departing [[Southampton]] on 10 April 1912
}}}}

      subject { template.variables }

      its_map(:name) { are_expected.to eq ['Ship image', 'Ship caption'] }
    end
  end
end
