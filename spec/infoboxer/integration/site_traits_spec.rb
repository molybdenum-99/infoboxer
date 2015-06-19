# encoding: utf-8
module Infoboxer
  describe 'Integration of MediaWiki::Traits into data' do
    before do
      MediaWiki::Traits.selectors.clear
      MediaWiki::Traits.templates.clear
      MediaWiki::Traits.domains.clear
    end
    
    describe 'template expansion on-the-fly' do
      let(:klass){
        Class.new(MediaWiki::Traits) do
          templates_text(
            '!' => '|',
            ',' => '·'
          )
          template('join'){|t| Nodes[*t.variables.map(&:children)]}
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

        it{should == [
          Text.new('before | textand '),
          Italic.new(Text.new('italics')),
          Text.new(' after')
        ]}
      end
      
      context 'when multiline templates' do
        let(:source){
          "{{unknown|{{!}}\n\ntext\n\n{{,}}}}r"
        }
        subject{nodes.first.variables.first.children}
        it{should == [
          Text.new('|'),
          Paragraph.new(Text.new('text')),
          Paragraph.new(Text.new('·')),
        ]}
      end

      context 'when templates in image caption' do
        let(:source){
          "[[File:image.png|This {{!}} that]]"
        }

        subject{
          nodes.first.caption
        }

        it{should == [
          Text.new('This | that')
        ]}
      end

      context 'when templates in tables' do
        let(:source){
          "{|\n|+Its in {{!}} caption!\n|}"
        }
        let(:table){Parser.paragraphs(source, traits).first}
        subject{table.lookup(TableCaption).first}
        its(:children){should == [
          Text.new('Its in | caption!')
        ]}
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

    describe 'context-dependent navigation' do
      let!(:klass){
        Class.new(MediaWiki::Traits) do
          domain 'en.wikipedia.org'

          selector :infoboxes, Template, name: /^Infobox /
        end
      }
      let(:traits){klass.new}
      let(:source){
        "{{Infobox country|some info}} [[Category:First]]\n\n[[Category:Second]]"
      }
      let(:client){MediaWiki.new('http://en.wikipedia.org/w/api.php')}
      let(:page){
        Page.new(client, Parser.paragraphs(source), traits: traits)
      }
      let(:para){
        page.children.first
      }
      it 'should navigate context-relative' do
        expect(page.infoboxes.count).to eq 1
        expect(page.categories.count).to eq 2
        expect(page.infoboxes.first.name).to eq 'Infobox country'
        expect(page.categories.map(&:name)).to eq %w[First Second]
      end

      it 'should navigate for nodes tooo' do
        expect(para.categories.count).to eq 1
        expect(para.categories.map(&:name)).to eq %w[First]
      end
    end

  end
end
