# encoding: utf-8
require 'infoboxer/parser'

module Infoboxer
  describe Parser, 'templates' do
    let(:ctx){Parser::Context.new(source)}
    let(:parser){Parser.new(ctx)}

    let(:nodes){parser.inline}
    let(:template){nodes.first}
    subject{template}

    context 'simplest' do
      let(:source){ '{{the name}}' }

      it{should be_a(Tree::Template)}
      its(:name){should == 'the name'}
    end

    context 'with unnamed variable' do
      let(:source){ '{{the name|en}}' }

      it{should be_a(Tree::Template)}
      its(:name){should == 'the name'}
      its(:variables){should == [Tree::Var.new('1', Tree::Text.new('en'))]}
    end

    context 'with named variable' do
      let(:source){ '{{the name|lang=en}}' }

      it{should be_a(Tree::Template)}
      its(:name){should == 'the name'}
      its(:variables){should == [Tree::Var.new('lang', Tree::Text.new('en'))]}
    end

    context 'with empty variable' do
      let(:source){ '{{the name|lang=}}' }

      it{should be_a(Tree::Template)}
      its(:name){should == 'the name'}
      its(:variables){should == [Tree::Var.new('lang')]}
    end

    context 'with named and unnamed mixed' do
      let(:source){ '{{the name|test1|foo=bar|test2}}' }

      it 'should have variables named consistently' do
        expect(subject.variables.map(&:name)).to eq ['1', 'foo', '2']
      end
    end

    context 'with empty line' do
      let(:source){ '{{the name|}}' }

      it{should be_a(Tree::Template)}
      its(:name){should == 'the name'}
      its(:variables){should == []}
    end

    context 'with "=" symbol in variable' do
      let(:source){ '{{the name|formula=1+2=3}}' }

      its(:variables){should == [Tree::Var.new('formula', Tree::Text.new('1+2=3'))]}
    end

    context 'with link in variable' do
      let(:source){ '{{the name|[[Argentina|Ar]]}}' }

      it{should be_a(Tree::Template)}
      its(:name){should == 'the name'}
      its(:variables){should ==
        [
          Tree::Var.new('1', [Tree::Wikilink.new('Argentina', Tree::Text.new('Ar'))])
        ]
      }
    end

    context 'with paragraphs in variable' do
      let(:source){ "{{the name|var=some\nmultiline\n''text''}}" }
      it{should be_a(Tree::Template)}
      it 'should preserve all content' do
        expect(subject.variables.first.children.map(&:class)).to eq [Tree::Text, Tree::Paragraph]
      end
    end

    context 'with newlines before nested template' do
      let(:source){ "{{the name|var=\n {{nested}}}}" }
      it{should be_a(Tree::Template)}
      it 'should preserve all content' do
        expect(subject.variables.first.children).to all(be_a(Tree::Template))
      end
    end

    context 'with newlines before variable name' do
      let(:source){ "{{the name|\nvar=test}}" }
      it{should be_a(Tree::Template)}
      it 'should preserve all content' do
        expect(subject.variables.first.name).to eq 'var'
      end
    end

    context 'with newline+space before next var' do
      let(:source){ "{{the name|var=test\n |var2=foo}}" }
      it{should be_a(Tree::Template)}
      it 'should preserve all content' do
        expect(subject.variables.first.children).to eq [Tree::Text.new('test')]
      end
    end

    context 'with <ref> and other template in variable' do
      let(:source){ "{{the name|<ref>some\nmultiline\nreference</ref> {{and|other-template}}|othervar}}" }
      it{should be_a(Tree::Template)}
      its(:'variables.count'){should == 2}
    end

    context 'with other template in variable - newlines' do
      let(:source){ "{{the name|first=\n {{\nother-template\n }}\n| othervar}}" }
      it{should be_a(Tree::Template)}
      its(:'variables.count'){should == 2}
    end

    context 'with complex lists inside' do
      let(:source){unindent(%Q{
        {{Infobox country
        |footnote_a = {{note|note-lang}}''[[De facto]]'' at all government levels.{{efn-ua|name=es|Though not declared official ''[[de jure]]'', the Spanish language is the only one used in the wording of laws, decrees, resolutions, official documents and public acts.}} In addition, some provinces have official ''[[de jure]]'' languages:
        :{{,}}[[Guaraní language|Guaraní]] in [[Corrientes Province]].<ref name=gn>{{cite Argentine law|jur=CN|l=5598|date=22 de octubre de 2004}}</ref>
        :{{,}}[[Kom language (South America)|Kom]], [[Moqoit language|Moqoit]] and [[Wichi language|Wichi]], in [[Chaco Province]].<ref name=kom>{{cite Argentine law|jur=CC|l=6604|bo=9092|date=28 de julio de 2010}}</ref>
        |footnote_b = {{note|note-train}}Trains ride on left.
        }}
      })}

      it{should be_a(Tree::Template)}
      its(:'variables.count'){should == 2}
    end

    context 'with simple variable inside' do
      let(:source){%Q{{{some template|lang=en|wtf|text=not a ''parameter''}}}}

      its(:'variables.count'){should == 3}
    end

    context 'magic words' do
      let(:source){%Q{{{formatnum:{{#expr: 14.3 * 2.589988110336 round 1}} }}}}

      it{should be_a(Tree::Template)}
      its(:name){should == 'formatnum'}
      its(:'variables.count'){should == 1}
      its(:'variables.first.name'){should == '1'}
      context 'magic inside magic' do
        subject{template.variables.first.children.first}
        it{should be_a(Tree::Template)}
        its(:name){should == '#expr'}
      end
    end

    context 'and now for really sick stuff!' do
      let(:source){ File.read('spec/fixtures/large_infobox.txt') }
      it{should be_a(Tree::Template)}
      its(:"variables.count"){should == 87}
    end
  end
end
