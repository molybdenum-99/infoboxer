# encoding: utf-8
module Infoboxer
  describe 'Integration of MediaWiki::Traits into data' do
    before do
      MediaWiki::Traits.templates.clear
      MediaWiki::Traits.domains.clear
    end
    
    describe 'template expansion on-the-fly' do
      let(:klass){
        Class.new(MediaWiki::Traits) do
          templates do
            inflow_template 'join'

            text('!' => '|', ',' => '·')
          end
        end
      }
      let(:traits){klass.new}
      let(:nodes){
        Parser.inline(source, traits)
      }

      context 'when simple nested templates' do
        let(:source){
          "before {{join|{{!}} text|and ''italics''}} after"
        }

        subject{
          nodes
        }

        its(:text){should == 'before | text and italics after'}
      end
      
      context 'when multiline templates' do
        let(:source){
          "{{unknown|{{!}}\n\ntext\n\nfoo {{,}}}}r"
        }
        subject{nodes.first.variables.first.children}
        it{should == [
          traits.templates.find('!').new('!'),
          Tree::Paragraph.new(Tree::Text.new('text')),
          Tree::Paragraph.new([Tree::Text.new('foo '), traits.templates.find(',').new(',')]),
        ]}
        its(:text){should == "|text\n\nfoo ·\n\n"}
      end

      context 'when templates in image caption' do
        let(:source){
          "[[File:image.png|This {{!}} that]]"
        }

        subject{
          nodes.first.caption
        }

        its(:text){should == 'This | that'}
      end

      context 'when templates in tables' do
        let(:source){
          "{|\n|+Its in {{!}} caption!\n|}"
        }
        let(:table){Parser.paragraphs(source, traits).first}
        subject{table.lookup(:TableCaption).first}
        its(:text){should == 'Its in | caption!'}
      end
    end

    #describe 'context selection by client' do
      #context 'when defined' do
        #let!(:klass){
          #Class.new(MediaWiki::Traits) do
            #domain 'en.wikipedia.org'
            
            #templates_text(
              #'!' => '|',
              #',' => '·'
            #)
            #template('join'){|t| Nodes[*t.variables.values]}
          #end
        #}
        #let(:client){MediaWiki.new('http://en.wikipedia.org/w/api.php')}
        #subject{client}
        #its(:context){should be_a(klass)}
      #end

      #context 'when not defined' do
      #end
    #end
  end
end
