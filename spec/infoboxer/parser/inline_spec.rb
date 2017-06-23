# encoding: utf-8

require 'infoboxer/parser'

module Infoboxer
  describe Parser, 'inline markup' do
    let(:ctx) { Parser::Context.new(source) }
    let(:parser) { Parser.new(ctx) }

    let(:nodes) { parser.inline }
    subject { nodes }

    context 'when just text' do
      let(:source) { 'just text' }

      it { is_expected.to eq [Tree::Text.new('just text')] }
    end

    context 'text with entities' do
      let(:source) { 'just textin&apos; with &Omega; symbol' }

      its(:'first.text') { is_expected.to eq "just textin' with \u{03A9} symbol" }
    end

    context 'when italic' do
      context 'simple' do
        let(:source) { "''italic''" }

        it { is_expected.to eq [Tree::Italic.new(Tree::Text.new('italic'))] }
      end

      context 'auto-closing of markup' do
        let(:source) { "''italic" }

        it { is_expected.to eq [Tree::Italic.new(Tree::Text.new('italic'))] }
      end
    end

    context 'when bold' do
      let(:source) { "'''bold'''" }

      it { is_expected.to eq [Tree::Bold.new(Tree::Text.new('bold'))] }

      context 'when mixed with apostrofe' do
        let(:source) { "L''''aritmetica'''" }

        it { is_expected.to eq [Tree::Text.new('L'), Tree::Bold.new(Tree::Text.new("'aritmetica"))] }
      end
    end

    context 'when bold italic' do
      let(:source) { "'''''bold italic'''''" }

      it { is_expected.to eq [Tree::BoldItalic.new(Tree::Text.new('bold italic'))] }
    end

    context 'when wikilink' do
      subject { nodes.first }

      context 'with label' do
        let(:source) { '[[Argentina|Ar]]' }

        it { is_expected.to be_a(Tree::Wikilink) }
        its(:link) { is_expected.to eq 'Argentina' }
        its(:children) { is_expected.to eq [Tree::Text.new('Ar')] }
      end

      context 'with formatted label' do
        let(:source) { "[[Argentina|Argentinian ''Republic'']]" }

        it { is_expected.to be_a(Tree::Wikilink) }
        its(:link) { is_expected.to eq 'Argentina' }
        its(:"children.count") { is_expected.to eq 2 }
      end

      context 'without label' do
        let(:source) { '[[Argentina]]' }

        it { is_expected.to be_a(Tree::Wikilink) }
        its(:link) { is_expected.to eq 'Argentina' }
        its(:children) { is_expected.to eq [Tree::Text.new('Argentina')] }
      end

      context 'with spans in label' do
        let(:source) { '[[Argentina|Argentinian <span>Republic]]' }

        it { is_expected.to be_a(Tree::Wikilink) }
        its(:link) { is_expected.to eq 'Argentina' }
        its(:"children.count") { is_expected.to eq 3 } # opening tag as separate thing
      end
    end

    context 'when external link' do
      subject { nodes.first }

      context 'with label' do
        let(:source) { '[http://google.com Google]' }

        it { is_expected.to be_a(Tree::ExternalLink) }
        its(:link) { is_expected.to eq 'http://google.com' }
        its(:children) { is_expected.to eq [Tree::Text.new('Google')] }
      end

      context 'without caption' do
        let(:source) { '[http://google.com]' }

        it { is_expected.to be_a(Tree::ExternalLink) }
        its(:link) { is_expected.to eq 'http://google.com' }
        its(:children) { is_expected.to eq [Tree::Text.new('http://google.com')] }
      end

      context 'not a link at all' do
        let(:source) { '[just text]' }

        it { is_expected.to be_a(Tree::Text) }
        its(:text) { is_expected.to eq '[just text]' }
      end

      context 'not a link: complex inline' do
        let(:source) { "This ''is [just text], trust'' me" }
        subject { nodes.find(Tree::Italic).first }

        its(:text) { is_expected.to eq 'is [just text], trust' }
      end

      context 'unclosed formatting inside' do
        # found at https://en.wikipedia.org/wiki/List_of_sovereign_states#Transnistria
        let(:source) { "[http://google.com ''Google]" }

        it { is_expected.to be_a(Tree::ExternalLink) }
        its(:link) { is_expected.to eq 'http://google.com' }
        its(:children) { is_expected.to eq [Tree::Italic.new(Tree::Text.new('Google'))] }
      end
    end

    context 'when HTML' do
      subject { nodes.first }

      context 'paired' do
        let(:source) { '<strike>Some text</strike>' }

        it { is_expected.to be_a(Tree::HTMLTag) }
        its(:tag) { is_expected.to eq 'strike' }
        its(:children) { is_expected.to eq [Tree::Text.new('Some text')] }
      end

      context 'with attributes' do
        let(:source) { '<strike class="airstrike" style="color: red;">Some text</strike>' }

        it { is_expected.to be_a(Tree::HTMLTag) }
        its(:tag) { is_expected.to eq 'strike' }
        its(:children) { is_expected.to eq [Tree::Text.new('Some text')] }
        its(:attrs) { is_expected.to eq(class: 'airstrike', style: 'color: red;') }
      end

      context 'self-closing' do
        let(:source) { '<br/>' }

        it { is_expected.to be_a(Tree::HTMLTag) }
        its(:tag) { is_expected.to eq 'br' }
        its(:children) { is_expected.to be_empty }
      end

      context 'self-closing with attrs' do
        let(:source) { '<div name=totalpop/>' }
        it { is_expected.to be_a(Tree::HTMLTag) }
        its(:children) { is_expected.to be_empty }
        its(:attrs) { is_expected.to eq(name: 'totalpop') }
      end

      context 'lonely opening' do
        let(:source) { '<strike>Some text' }

        it { is_expected.to be_a(Tree::HTMLOpeningTag) }
        its(:tag) { is_expected.to eq 'strike' }
      end

      context 'lonely closing' do
        let(:source) { '</strike>' }

        it { is_expected.to be_a(Tree::HTMLClosingTag) }
        its(:tag) { is_expected.to eq 'strike' }
      end

      context 'br' do
        let(:source) { '<br> test' }

        it { is_expected.to be_a(Tree::HTMLTag) }
        its(:children) { is_expected.to be_empty }
      end
    end

    context 'when nowiki' do
      context 'when non-empty' do
        let(:source) { "<nowiki> all kinds <ref> of {{highly}} irrelevant '' markup </nowiki>" }
        subject { nodes.first }

        it { is_expected.to eq Tree::Text.new(" all kinds <ref> of {{highly}} irrelevant '' markup ") }
      end

      context 'when empty' do
        let(:source) { 'The country is also a producer of [[industrial mineral]]<nowiki/>s.' }
        subject { nodes }
        it {
          is_expected.to eq [
            Tree::Text.new('The country is also a producer of '),
            Tree::Wikilink.new('industrial mineral'),
            Tree::Text.new('s.')
          ]
        }
      end
    end

    context 'when math' do
      let(:source) { "<math> all kinds <ref> of {{highly}} irrelevant '' markup </math>" }
      subject { nodes.first }

      it { is_expected.to eq Tree::Math.new(" all kinds <ref> of {{highly}} irrelevant '' markup ") }

      context 'math in templates' do
        let(:source) { '{{Ecuación|<math>g = \frac{F}{m} = \frac {G M_T}{{R_T}^2} </math>}}' }
        subject { nodes.lookup(:Template).first.variables.first.lookup(:Math).first }
        it { is_expected.to eq Tree::Math.new('g = \frac{F}{m} = \frac {G M_T}{{R_T}^2} ') }
      end
    end

    describe 'sequence' do
      subject { nodes }
      context 'plain' do
        let(:source) { "This is '''bold''' text with [[Some link|Link]]" }

        it 'should be parsed!' do
          expect(subject.count).to eq 4
          expect(subject.map(&:class)).to eq [Tree::Text, Tree::Bold, Tree::Text, Tree::Wikilink]
          expect(subject.map(&:text)).to eq ['This is ', 'bold', ' text with ', 'Link']
        end
      end

      context 'html + template' do
        let(:source) { '<br>{{small|(Sun of May)}}' }
        it 'should be parsed!' do
          expect(subject.count).to eq 2
          expect(subject.first).to be_kind_of(Tree::HTMLTag)
          expect(subject.last).to be_kind_of(Tree::Template)
        end
      end

      context 'text + html' do
        let(:source) { 'test <b>me</b>' }
        it 'should be parsed!' do
          expect(subject.count).to eq 2
          expect(subject.map(&:class)).to eq [Tree::Text, Tree::HTMLTag]
        end
      end

      context 'text, ref, template' do
        let(:source) { '4D S.A.S.<ref>{{Citation | url = http://www.4D.com | title = 4D}}</ref>' }
        it 'should be parsed!' do
          expect(subject.count).to eq 2
          expect(subject.map(&:class)).to eq [Tree::Text, Tree::Ref]
        end

        context 'even in "short" context' do
          let(:source) { '4D S.A.S.<ref>{{Citation | url = http://www.4D.com | title = 4D}}</ref>' }
          subject { parser.short_inline }
          it 'should be parsed!' do
            expect(subject.count).to eq 2
            expect(subject.map(&:class)).to eq [Tree::Text, Tree::Ref]
          end
        end
      end
    end

    describe 'nesting' do
      context 'simple' do
        let(:source) { "'''[[Bold link|Link]]'''" }
        subject { Parser.inline(source).first }

        it { is_expected.to be_kind_of(Tree::Bold) }
        its(:"children.first") { is_expected.to be_kind_of(Tree::Wikilink) }
      end

      context 'when cross-sected inside template' do
        let(:source) { "''italic{{tmpl|its ''italic'' too}}''" }

        its(:count) { is_expected.to eq 1 }
        its(:'first.text') { is_expected.to eq 'italic' }
        its(:'first.children.count') { is_expected.to eq 2 }
      end
    end
  end
end
