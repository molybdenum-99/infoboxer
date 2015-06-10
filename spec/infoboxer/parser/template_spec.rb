# encoding: utf-8
require 'infoboxer/parser'

module Infoboxer
  describe Parser, 'templates' do
    let(:ctx){Parse::Context.new(source)}
    let(:parser){Parser.new(ctx)}

    let(:nodes){parser.inline}
    subject{nodes.first}

    context 'simplest' do
      let(:source){ '{{the name}}' }

      it{should be_a(Template)}
      its(:name){should == 'the name'}
    end

    context 'with unnamed variable' do
      let(:source){ '{{the name|en}}' }

      it{should be_a(Template)}
      its(:name){should == 'the name'}
      its(:variables){should == {1 => [Text.new('en')]}}
    end

    context 'with named variable' do
      let(:source){ '{{the name|lang=en}}' }

      it{should be_a(Template)}
      its(:name){should == 'the name'}
      its(:variables){should == {lang: [Text.new('en')]}}
    end

    context 'with empty variable' do
      let(:source){ '{{the name|lang=}}' }

      it{should be_a(Template)}
      its(:name){should == 'the name'}
      its(:variables){should == {lang: []}}
    end

    context 'with empty line' do
      let(:source){ '{{the name|}}' }

      it{should be_a(Template)}
      its(:name){should == 'the name'}
      its(:variables){should == {}}
    end

    context 'with "=" symbol in variable' do
      let(:source){ '{{the name|formula=1+2=3}}' }

      its(:variables){should == {formula: [Text.new('1+2=3')]}}
    end

    context 'with link in variable' do
      let(:source){ '{{the name|[[Argentina|Ar]]}}' }

      it{should be_a(Template)}
      its(:name){should == 'the name'}
      its(:variables){should ==
        {1 =>
          [Wikilink.new('Argentina', [Text.new('Ar')])]
        }
      }
    end

    xcontext 'with paragraphs in variable' do
    end

    xcontext 'with <ref> and other template in variable' do
      let(:source){ "{{the name|<ref>some\nmultiline\nreference</ref> {{and|other-template}}}}" }
      it{should be_a(Template)}
    end

    xcontext 'and now for really sick stuff!' do
      let(:source){ File.read('spec/fixtures/large_infobox.txt') }
      it{should be_a(Template)}
      its(:"variables.count"){should == 87}
    end
  end
end
