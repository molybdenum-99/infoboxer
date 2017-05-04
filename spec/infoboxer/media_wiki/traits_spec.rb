# encoding: utf-8
module Infoboxer
  describe MediaWiki::Traits do
    before do
      described_class.templates.clear
      described_class.domains.clear
    end

    after(:all){
      # restoring after cleanup
      verbose, $VERBOSE = $VERBOSE, nil # suppressing "constant redefined" warning
      load 'lib/infoboxer/definitions/en.wikipedia.org.rb'
      $VERBOSE = verbose
    }

    context 'definition' do
      let(:klass){Class.new(described_class)}
      let(:traits){klass.new}

      context 'templates' do
        before do
          klass.templates{
            template '!' do
              def text
                '!'
              end
            end
          }
        end

        subject{traits.templates.find('!')}
        it{should be_a(Class)}
        it{should < Templates::Base}
        its(:inspect){should == 'Infoboxer::Templates::Template[!]'}

        context 'definition helpers' do
          before{
            klass.templates{
              replace '!' => '|', ',' => '·'
            }
          }

          context 'text replacements' do
            let(:template){traits.templates.find('!')}
            subject{template.new('!')}
            its(:text){should == '|'}
          end
        end
      end

      describe 'binding to domain' do
        before{
          klass.domain 'in.wikipedia.org'
        }
        subject{MediaWiki::Traits.get('in.wikipedia.org')}
        it{should be_a(klass)}

        context 'when non-bound domain' do
          subject{MediaWiki::Traits.get('fr.wikipedia.org')}
          it{should be_a(MediaWiki::Traits)}
        end
      end

      describe 'definition-and-binding' do
        let!(:klass){
          MediaWiki::Traits.for('in.wikipedia.org'){
            templates{
              show 'foo'
            }
          }
        }
        let(:traits){MediaWiki::Traits.get('in.wikipedia.org')}
        it 'should be defined' do
          expect(traits).to be_kind_of(klass)
        end
        subject{traits.templates.find('foo')}
        it{should be_a(Class)}
        it{should < Templates::Show}

        it 'should continue definition' do
          MediaWiki::Traits.for('in.wikipedia.org'){
            templates{
              show 'bar'
            }
          }
          expect(traits.templates.find('foo')).to be < Templates::Show
          expect(traits.templates.find('bar')).to be < Templates::Show
        end
      end

      describe 'on-the-fly enrichment' do
        before{
          klass.domain 'in.wikipedia.org'
        }
        subject{ MediaWiki::Traits.get('in.wikipedia.org', {namespaces: [{'canonical' => 'File', '*' => 'Fichier'}]})}
        its(:file_namespace) { is_expected.to contain_exactly('File', 'Fichier')}
      end
    end
  end
end
