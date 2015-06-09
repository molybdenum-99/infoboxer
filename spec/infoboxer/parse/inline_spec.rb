# encoding: utf-8
module Infoboxer
  describe Parse, :inline do
    describe 'simple inline markup' do
      describe 'one item' do
        let(:nodes){Parse.inline(source)}
        let(:node){nodes.first}
        subject{node}

        context 'when just text' do
          let(:source){'just text'}
          
          it{should be_a(Text)}
          its(:text){should == 'just text'}
        end

        context 'text with entities' do
          let(:source){'just textin&apos; with &Omega; symbol'}

          its(:text){should == "just textin' with \u{03A9} symbol"}
        end

        context 'when italic' do
          context 'simple' do
            let(:source){"''italic''"}
            
            it{should be_a(Italic)}
            its(:text){should == 'italic'}
          end

          context 'when cross-sected inside template' do
            let(:source){"''italic{{tmpl|its ''italic'' too}}''"}
            
            it{should be_a(Italic)}
            its(:text){should == 'italic'}
          end

          context 'auto-closing of markup' do
            let(:source){"''italic"}
            
            it{should be_a(Italic)}
            its(:text){should == 'italic'}
          end
        end

        context 'when bold' do
          let(:source){"'''bold'''"}
          
          it{should be_a(Bold)}
          its(:text){should == 'bold'}
        end

        context 'when bold italic' do
          let(:source){"'''''bold italic'''''"}
          
          it{should be_a(BoldItalic)}
          its(:text){should == 'bold italic'}
        end

        context 'when wikilink' do
          context 'with label' do
            let(:source){'[[Argentina|Ar]]'}

            it{should be_a(Wikilink)}
            its(:link){should == 'Argentina'}
            its(:children){should == [Text.new('Ar')]}
          end

          context 'with formatted label' do
            let(:source){"[[Argentina|Argentinian ''Republic'']]"}

            it{should be_a(Wikilink)}
            its(:link){should == 'Argentina'}
            its(:"children.count"){should == 2}
          end

          context 'without label' do
            let(:source){'[[Argentina]]'}

            it{should be_a(Wikilink)}
            its(:link){should == 'Argentina'}
            its(:children){should == [Text.new('Argentina')]}
          end
        end

        context 'when external link' do
          context 'with label' do
            let(:source){'[http://google.com Google]'}

            it{should be_a(ExternalLink)}
            its(:link){should == 'http://google.com'}
            its(:children){should == [Text.new('Google')]}
          end

          context 'without caption' do
            let(:source){'[http://google.com]'}

            it{should be_a(ExternalLink)}
            its(:link){should == 'http://google.com'}
            its(:children){should == [Text.new('http://google.com')]}
          end

          context 'not a link at all' do
            let(:source){'[just text]'}

            it{should be_a(Text)}
            its(:text){should == '[just text]'}
          end
        end

        context 'when HTML' do
          context 'paired' do
            let(:source){'<strike>Some text</strike>'}

            it{should be_a(HTMLTag)}
            its(:tag){should == 'strike'}
            its(:children){should == [Text.new('Some text')]}
          end

          context 'with attributes' do
            let(:source){'<strike class="airstrike" style="color: red;">Some text</strike>'}

            it{should be_a(HTMLTag)}
            its(:tag){should == 'strike'}
            its(:children){should == [Text.new('Some text')]}
            its(:attrs){should ==
              {class: 'airstrike', style: 'color: red;'}
            }
          end

          context 'self-closing' do
            let(:source){'<br/>'}

            it{should be_a(HTMLTag)}
            its(:tag){should == 'br'}
            its(:children){should be_empty}
          end

          context 'self-closing with attrs' do
            let(:source){'<div name=totalpop/>'}
            it{should be_a(HTMLTag)}
            its(:children){should be_empty}
            its(:attrs){should == {name: 'totalpop'}}
          end

          context 'lonely opening' do
            let(:source){'<strike>Some text'}

            it{should be_a(HTMLOpeningTag)}
            its(:tag){should == 'strike'}
          end

          context 'lonely closing' do
            let(:source){'</strike>'}

            it{should be_a(HTMLClosingTag)}
            its(:tag){should == 'strike'}
          end

          context 'br' do
            let(:source){'<br> test'}

            it{should be_a(HTMLTag)}
            its(:children){should be_empty}
          end
        end

        context 'when image' do
          context 'when simplest' do
            let(:source){
              %q{[[File:SantaCruz-CuevaManos-P2210651b.jpg]]}
            }

            it{should be_a(Image)}
            its(:path){should == 'SantaCruz-CuevaManos-P2210651b.jpg'}
          end

          context 'when complex' do
            # real example from http://en.wikipedia.org/wiki/Argentina
            # I love you, Wikipedia!!!!
            let(:source){
              %q{[[File:SantaCruz-CuevaManos-P2210651b.jpg|thumb|200px|The [[Cueva de las Manos|Cave of the Hands]] in [[Santa Cruz province, Argentina|Santa Cruz province]], with indigenous artwork dating from 13,000–9,000 years ago|alt=Stencilled hands on the cave's wall]]}
            }

            it{should be_a(Image)}
            its(:path){should == 'SantaCruz-CuevaManos-P2210651b.jpg'}
            its(:type){should == 'thumb'}
            its(:width){should == 200}
            its(:alt){should == "Stencilled hands on the cave's wall"}

            describe 'caption' do
              subject{node.caption}

              it{should be_a(Nodes)}
              it 'should preserve all data' do
                expect(subject.map(&:class)).to eq \
                  [Text, Wikilink, Text, Wikilink, Text]

                expect(subject.map(&:text)).to eq [
                  'The ',
                  'Cave of the Hands',
                  ' in ',
                  'Santa Cruz province',
                  ', with indigenous artwork dating from 13,000–9,000 years ago'
                ]
              end
            end
          end

          context 'with non-default site traits provided' do
            let(:source){
              %Q{[[Fichier:SantaCruz-CuevaManos-P2210651b.jpg|thumb|200px]]}
            }
            let(:traits){
              MediaWiki::Traits.new(file_prefix: 'Fichier')
            }
            let(:nodes){Parse.inline(source, traits)}

            it{should be_an(Image)}
            its(:path){should == 'SantaCruz-CuevaManos-P2210651b.jpg'}

            it 'should parse File: prefix' do
              expect(
                Parse.inline(%Q{[[File:SantaCruz-CuevaManos-P2210651b.jpg|thumb|200px]]}, traits).first
              ).to be_an(Image)
            end
          end
        end

        context 'when <ref>' do
          context 'simple' do
            let(:source){
              "<ref>The text\nof the reference</ref>"
            }

            it{should ==
              Ref.new([
                Text.new('The text'),
                Paragraph.new(Text.new('of the reference'))
              ])
            }
          end

          context 'with params' do
            let(:source){
              "<ref name=gini>\nThe text\n\nof the reference</ref>"
            }

            it{should be_kind_of(Ref)}
            its(:params){should == {name: 'gini'}}
          end

          context 'self-closing' do
            let(:source){'<ref name=totalpop/>'}
            it{should be_kind_of(Ref)}
            its(:params){should == {name: 'totalpop'}}
          end

          context 'with incomplete markup' do
            let(:source){
              "<ref>''bad markup!</ref>"
            }

            it{should be_kind_of(Ref)}
            its(:children){should == [Italic.new(Text.new("bad markup!"))]}
          end
        end
        
        # TODO: check what we do with incorrect markup
      end

      describe 'sequence' do
        subject{Parse.inline(source)}
        context 'plain' do
          let(:source){"This is '''bold''' text with [[Some link|Link]]"}

          it 'should be parsed!' do
            expect(subject.count).to eq 4
            expect(subject.map(&:class)).to eq [Text, Bold, Text, Wikilink]
            expect(subject.map(&:text)).to eq ['This is ', 'bold', ' text with ', 'Link']
          end
        end

        context 'html + template' do
          let(:source){'<br>{{small|(Sun of May)}}'}
          it 'should be parsed!' do
            expect(subject.count).to eq 2
            expect(subject.map(&:class)).to eq [HTMLTag, Template]
          end
        end
      end

      describe 'nesting' do
        let(:source){"'''[[Bold link|Link]]'''"}
        subject{Parse.inline(source).first}

        it{should be_kind_of(Bold)}
        its(:"children.first"){should be_kind_of(Wikilink)}
      end
    end

    describe 'inline markup spanning for several lines' do
      describe 'image' do
        # also real-life example!
        let(:source){
          "[[File:Diplomatic missions of Argentina.png|thumb|250px|Argentine diplomatic missions:\n"\
          "<div style=\"font-size:90%;\">\n"\
          "{{legend4|#22b14c|Argentina}}\n"\
          "{{legend4|#2f3699|Nations hosting a resident diplomatic mission}}\n"\
          "{{legend4|#b9b9b9|Nations without a resident diplomatic mission}}\n"\
          "</div>]]"
        }
        subject{Parse.inline(source).first}

        it{should be_a(Image)}
        its(:path){should == 'Diplomatic missions of Argentina.png'}
        its(:width){should == 250}
        it 'should have a caption ' do
          expect(subject.caption.map(&:class)).to eq \
            [Text, Paragraph]
        end
      end
    end

    context 'when template' do
      let(:node){Parse.inline(source).first}
      subject{node}

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

      context 'with <ref> and other template in variable' do
        let(:source){ "{{the name|<ref>some\nmultiline\nreference</ref> {{and|other-template}}}}" }
        it{should be_a(Template)}
      end

      context 'and now for really sick stuff!' do
        let(:source){ File.read('spec/fixtures/large_infobox.txt') }
        it{should be_a(Template)}
        its(:"variables.count"){should == 87}
      end
    end
  end
end
