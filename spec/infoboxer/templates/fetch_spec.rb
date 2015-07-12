# encoding: utf-8
module Infoboxer
  describe Template, 'fetch*' do
    let(:src){File.read('spec/fixtures/large_infobox.txt')}
    let(:template){Parser.inline(src).first}
    
    context :fetch do
      context 'one value by string' do
        subject{template.fetch('conventional_long_name')}
        it{should be_a(Nodes)}
        its(:count){should == 1}
        its(:text){should == 'Argentine Republic'}
      end

      context 'multiple values by regexp' do
        subject{template.fetch(/leader_title\d+/)}

        its(:count){should == 3}
        it{should all(be_a(TemplateVariable))}
        it 'should be all variables queried' do
          expect(subject.map(&:name)).to eq ['leader_title1', 'leader_title2', 'leader_title3']
        end
      end

      context 'multiple values by list' do
        subject{template.fetch('leader_title1', 'leader_name1')}
        its(:count){should == 2}
        it 'should be all variables queried' do
          expect(subject.map(&:name)).to eq ['leader_title1', 'leader_name1']
        end
      end
    end

    context :fetch_hash do
      subject{template.fetch_hash('leader_title1', 'leader_name1')}
      it{should be_a(Hash)}
      its(:keys){should == ['leader_title1', 'leader_name1']}
      its(:values){should all(be_a(TemplateVariable))}
    end

    context :fetch_date do
      let(:src){'{{birth date and age|1953|2|19|df=y}}'}
      subject{template.fetch_date('1', '2', '3')}
      it{should == Date.new(1953, 2, 19)}
    end

    context :fetch_coord do
    end
  end
end
