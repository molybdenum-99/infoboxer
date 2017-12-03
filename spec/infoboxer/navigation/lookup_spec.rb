module Infoboxer
  describe Navigation::Lookup do
    let(:document) {
      Parser.document(%{
      Test in first ''paragraph''
      === Heading ===
      {| some=table
      |With
      * cool list
      * ''And'' deep test
      * some more
      |}
      }.strip.gsub(/\n\s+/m, "\n"))
    }

    describe :lookup do
      context 'without any args' do
        subject {
          document.lookup
        }

        it { is_expected.to be_kind_of(Tree::Nodes) }
        its(:count) { is_expected.to be > 10 }
      end

      context 'with block' do
        subject {
          document.lookup { |n| n.is_a?(Tree::Text) && n.text =~ /test/i }
        }

        it { is_expected.to be_kind_of(Tree::Nodes) }
        it {
          is_expected.to eq [
            Tree::Text.new('Test in first '),
            Tree::Text.new(' deep test')
          ]
        }
      end

      context 'by class' do
        subject { document.lookup(Tree::Table) }

        its(:count) { is_expected.to eq 1 }
      end

      context 'by class & fields' do
        subject {
          document.lookup(Tree::Text, text: /test/i)
        }

        it { is_expected.to be_kind_of(Tree::Nodes) }
        it {
          is_expected.to eq [
            Tree::Text.new('Test in first '),
            Tree::Text.new(' deep test')
          ]
        }
      end

      context 'by accessor' do
        before {
          Tree::ListItem.module_eval {
            def first_list_item?
              index.zero?
            end
          }
        }
        subject {
          document.lookup(:first_list_item?)
        }

        its(:count) { is_expected.to eq 1 }
        its(:text) { is_expected.to eq "* cool list\n" }
      end

      context 'by class-ish symbol' do
        subject { document.lookup(:Table) }

        its(:count) { is_expected.to eq 1 }
        its(:first) { is_expected.to be_a(Tree::Table) }
      end

      context 'everything at once' do
        subject {
          document.lookup(Tree::Text, text: /test/i) { |n| n.text.length == 10 }
        }

        it { is_expected.to be_kind_of(Tree::Nodes) }
        it {
          is_expected.to eq [
            Tree::Text.new(' deep test')
          ]
        }
      end

      context 'by fields which only some subclasses have' do
        subject { document.lookup(Tree::Heading, level: 3) }

        its(:count) { is_expected.to eq 1 }
      end
    end

    describe :lookup_children do
      let(:cell) { document.lookup(Tree::TableCell).first }

      context 'direct child only' do
        subject { cell.lookup_children(Tree::Text) }

        its(:count) { is_expected.to eq 1 }
        its(:first) { is_expected.to eq Tree::Text.new('With') }
      end

      context 'indirect child' do
        subject { cell.lookup_children(Tree::ListItem) }

        it { is_expected.to be_empty }
      end
    end

    describe 'chain of lookups' do
      subject {
        document
          .lookup(Tree::List)
          .lookup(Tree::ListItem)
          .lookup_children(text: /test/)
      }

      it { is_expected.to eq [Tree::Text.new(' deep test')] }
    end

    describe :parent do
      subject { document.lookup(Tree::TableCell).first }

      its(:parent) { is_expected.to be_a(Tree::TableRow) }
    end

    describe :lookup_parents do
      let(:cell) { document.lookup(Tree::TableCell).first }

      context 'parent found' do
        subject { cell.lookup_parents(Tree::Table) }

        its(:count) { is_expected.to eq 1 }
        its(:first) { is_expected.to be_a(Tree::Table) }
      end
    end

    describe :index do
      subject { document.lookup(Tree::Heading).first }

      its(:index) { is_expected.to eq 1 }
    end

    describe :siblings do
      subject { document.lookup(Tree::ListItem, text: /cool list/).first }

      its(:'siblings.count') { is_expected.to eq 2 }
      its(:siblings) { is_expected.to all(be_a(Tree::ListItem)) }
    end

    describe :lookup_siblings do
      let!(:node) { document.lookup(Tree::ListItem, text: /cool list/).first }

      subject { node.lookup_siblings(text: /test/) }

      its(:count) { is_expected.to eq 1 }
      it { is_expected.to all(be_a(Tree::ListItem)) }
    end

    describe :prev_siblings do
      subject { document.lookup(Tree::ListItem, text: /deep test/).first }

      its(:'prev_siblings.count') { is_expected.to eq 1 }
      its(:'prev_siblings.text') { is_expected.to include('cool list') }
    end

    describe :next_siblings do
      subject { document.lookup(Tree::ListItem, text: /deep test/).first }

      its(:'next_siblings.count') { is_expected.to eq 1 }
      its(:'next_siblings.text') { is_expected.to include('some more') }
    end

    describe :lookup_prev_siblings do
      let!(:node) { document.lookup(Tree::ListItem, text: /deep test/).first }

      it 'works' do
        expect(node.lookup_prev_siblings(text: /cool/).count).to eq 1
        expect(node.lookup_prev_siblings(text: /more/).count).to eq 0
      end
    end

    describe :lookup_next_siblings do
      let!(:node) { document.lookup(Tree::ListItem, text: /deep test/).first }

      it 'works' do
        expect(node.lookup_next_siblings(text: /cool/).count).to eq 0
        expect(node.lookup_next_siblings(text: /more/).count).to eq 1
      end
    end
  end
end
