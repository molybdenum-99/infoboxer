# encoding: utf-8
require 'infoboxer/media_wiki/traits/en.wikipedia.org'

module Infoboxer
  describe 'calculated templates' do
    let(:traits){WikipediaEn.new}
    let(:template_vars){
      variables.each_with_index.map{|v, i| TemplateVariable.new((i+1).to_s, Text.new(v))}
    }
    subject{traits.templates.find(name).new(name, Nodes[*template_vars])}
    
    describe '{{Convert}}' do
      let(:name){'Convert'}
      
      context 'simplest case' do
        let(:variables){%w[120 km mi]}

        it{should be_kind_of(InFlowTemplate)}
        
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
        let(:variables){%w[1985 07 01]}

        it{should be_kind_of(InFlowTemplate)}
        
        its(:text){should == '30 years'}
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
