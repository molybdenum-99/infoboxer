# encoding: utf-8
module Infoboxer
  describe MediaWiki::Traits do
    before do
      described_class.templates.clear
      described_class.domains.clear
    end
    
    context 'definition' do
      let(:klass){Class.new(described_class)}
      let(:traits){klass.new}

      context 'templates' do
        before do
          klass.templates{
            inflow_template '!' do
              def to_text
                '!'
              end
            end
          }
        end

        subject{traits.templates.find('!')}
        it{should be_a(Class)}
        it{should < InFlowTemplate}
        its(:inspect){should == '#<InFlowTemplate[!]>'}

        context 'definition helpers' do
          before{
            klass.templates{
              text '!' => '|', ',' => '·'
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
          klass.domain 'en.wikipedia.org'
        }
        subject{MediaWiki::Traits.get('en.wikipedia.org')}
        it{should be_a(klass)}

        context 'when non-bound domain' do
          subject{MediaWiki::Traits.get('fr.wikipedia.org')}
          it{should be_a(MediaWiki::Traits)}
        end
      end

      describe 'on-the-fly enrichment' do
        before{
          klass.domain 'en.wikipedia.org'
        }
        subject{MediaWiki::Traits.get('en.wikipedia.org', file_prefix: 'File')}
        its(:file_prefix){should == ['File']}
      end
    end
  end
end
