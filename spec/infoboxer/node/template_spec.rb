# encoding: utf-8
module Infoboxer
  describe Template do
    let(:template){Parser.inline(unindent(source)).first}
    
    describe 'variables as params' do
      let(:source){%Q{
        {{some template|lang=en|wtf|text=not a ''parameter''}}
      }}

      subject{template.params}
      it{should == {'lang' => 'en', '2' => 'wtf'}}
    end

    describe 'fetching variable value' do
      context 'when by text' do
        let(:source){%Q{
          {{some template|lang=en|wtf|text=something ''complex''}}
        }}
        subject{template.fetch('text')}
        it{should be_a(Nodes)}
        its(:count){should == 1}
        its(:first){should be_a(TemplateVariable)}
        its(:'first.text'){should == 'something complex'}
      end

      context 'when by regexp' do
        let(:source){%Q{
          {{cities
          |city_1 = buenos aires
          |city_2 = vorkuta
          |city_3 = varanasi
          }}
        }}
        subject{template.fetch(/city_\d+/)}
        it{should be_a(Nodes)}
        its(:count){should == 3}
        it{should all(be_a(TemplateVariable))}
        its(:'first.text'){should == 'buenos aires'}
      end

      context 'when non-existing' do
        let(:source){%Q{
          {{some template}}
        }}
        subject{template.fetch('text')}
        it{should be_a(Nodes)}
        it{should be_empty}
      end
    end
  end
end
