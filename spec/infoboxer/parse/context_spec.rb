# encoding: utf-8
module Infoboxer
  describe Parse::Context do
    let(:ctx){Parse::Context.new(unindent(source))}
    
    describe 'lines' do
      let(:source){%Q{
        one
        two
        three
      }}

      subject{ctx}
      context 'initially' do
        its(:current){should == 'one'}
        its(:next_lines){should == %w[two three]}
        it{should_not be_eof}
        its(:lineno){should == 0}
      end

      context :next! do
        before{subject.next!}
        its(:current){should == 'two'}
        its(:next_lines){should == %w[three]}
        its(:lineno){should == 1}
      end

      context :prev! do
        before{subject.next!; subject.prev!}
        its(:current){should == 'one'}
        its(:next_lines){should == %w[two three]}
        its(:lineno){should == 0}
      end

      context :eof? do
        before{3.times{subject.next!}}
        it{should be_eof}
      end
    end

    describe 'scan' do
      let(:source){%Q{
        one '' {{ two
        }} two
        three
      }}
      
      describe :scan do
        it 'scans existing' do
          expect(ctx.scan(/o../)).to eq 'one'
        end

        it 'not scans non-existing' do
          expect(ctx.scan(/t../)).to be_nil
        end

        it 'scans only one line' do
          expect(ctx.scan(/o.+three/m)).to be_nil
        end
      end

      describe :scan_until do
        it 'scans, but drops pattern itself' do
          expect(ctx.scan_until(/two/)).to eq "one '' {{ "
          expect(ctx.scan_until(/}}/)).to be_nil
        end

        it 'has option to leave pattern' do
          expect(ctx.scan_until(/two/, true)).to eq "one '' {{ two"
        end
      end

      describe :scan_through_until do
        it 'scans across lines and counts brackets' do
          expect(ctx.scan_through_until(/two/)).to eq "one '' {{ two\n}} "
        end
      end
    end

    describe 'error throwing' do
    end

    describe 'site traits' do
      let(:traits){MediaWiki::Traits.new(file_prefix: 'Файл')}
      let(:source){''}
      let(:ctx){Parse::Context.new(source, traits)}
      subject{ctx.re[:file_prefix]}

      it{should == /(File|Файл):/}
    end
  end
end
