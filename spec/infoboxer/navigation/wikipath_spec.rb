module Infoboxer
  describe Navigation::Wikipath do
    #before(:all) { @document = Parser.document(File.read('spec/fixtures/argentina.wiki')) }

    #let(:document) { @document }

    let(:document){
      Parser.document(%Q{
        |Test in first ''paragraph''
        |
        | {{Use dmy dates|date=July 2014}}
        |
        |=== Section 1 ===
        |
        |{| some=table
        ||With
        |* cool list
        |* ''And'' deep test
        |* some more
        ||}
        |
        | {{template}}
      }.unindent)
    }

    subject { ->(path) { document.wikipath(path) } }

    its(['//template']) { is_expected.to be_a(Tree::Nodes).and_not be_empty.and all be_a(Tree::Template) }
    its(['//table//list//italic']) { is_expected.to have_attributes(text: 'And') }
    its(['//template[name=/^Use/]']) {
      is_expected
        .to include(have_attributes(name: 'Use dmy dates'))
        .and_not include(have_attributes(name: 'template'))
    }
    its(['//table//list/list_item[first]']) {
      is_expected
        .to include(have_attributes(text_: '* cool list'))
        .and_not include(have_attributes(text_: '* some more'))
    }
    its(['//template/var[name=date]']) { is_expected.to include(be_a(Tree::Var).and have_attributes(name: 'date')) }
    its(['/section']) { is_expected.not_to be_empty }
    its(['/section[heading=Section 1]']) { is_expected.to eq [document.sections.first] }
  end
end
