# encoding: utf-8
module Infoboxer
  describe 'calculated templates' do
    let(:traits){MediaWiki::Traits.get('en.wikipedia.org')}
    let(:template_vars){
      variables.each_with_index.map{|v, i| Tree::Var.new((i+1).to_s, Tree::Text.new(v))}
    }
    subject{traits.templates.find(name).new(name, Tree::Nodes[*template_vars])}
    
    describe '{{Convert}}' do
      let(:name){'Convert'}
      
      context 'simplest case' do
        let(:variables){%w[120 km mi]}

        it{should be_kind_of(Templates::Base)}
        
        its(:text){should == '120 km'}
        its(:value1){should == '120'}
        its(:value2){should be_nil}
        its(:measure_from){should == 'km'}
        its(:measure_to){should == 'mi'}
      end

      context 'with between sign' do
        let(:variables){%w[120 × 15 m acres]}
        its(:text){should == '120 × 15 m'}
        its(:value1){should == '120'}
        its(:value2){should == '15'}
        its(:between){should == '×'}
        its(:measure_from){should == 'm'}
        its(:measure_to){should == 'acres'}
      end
    end

    describe '{{Coord}}' do
    end

    describe '{{Age}}' do
      let(:name){'Age'}
      
      context 'one date' do
        # FIXME: use timecomp here
        let(:variables){%w[1985 07 01]}

        it{should be_kind_of(Templates::Base)}
        
        its(:text){should == '30 years'}
      end

      context 'two dates' do
        let(:variables){%w[1985 07 01 1995 08 15]}
        
        its(:text){should == '10 years'}
      end
    end

    describe '{{Birth date and age}}' do
    end

    describe '{{Birth date}}' do
    end

    describe '{{Time ago}}' do
    end
  end
end
